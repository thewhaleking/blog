---
title: "Two caches in a trench coat: CachedFetcher and the art of not making the same request twice"
date: 2026-06-02T13:36:25+02:00
authors: ["thewhaleking"]
tags: ["engineering", "asyncio", "python"]
summary: "An async caching primitive that does two jobs at once, memoization and request coalescing, and why being able to switch one of them off gives you deduplication that can't go stale."
# Optional cover image co-located in this post's folder:
# cover:
#   image: "cover.png"
#   alt: ""
draft: false
---

Here's a line of async Python that looks innocent and is quietly wasteful:

```py
balances, metadata, events = await asyncio.gather(
    get_balances(block_hash=None),
    get_metadata(block_hash=None),
    get_events(block_hash=None),
)
```

Each of those three calls, somewhere deep in its call stack, needs to resolve "what block are we even talking about?" and so each one independently fires off a `chain_getHead` RPC to the node. Three network round-trips to answer the *same* question, at the *same* instant, for three callers who would have happily shared one answer.

You didn't write that duplication, and you can't easily see it. It falls out of composing independent operations that happen to share a dependency. `CachedFetcher` is what we built to get rid of it, and the idea behind it is small enough to be worth walking through.

## Background

When I started working on Bittensor, I was tasked with making it “faster”. Now, in programming, “faster” can mean a number of things, but generally speaking, end-users care about the time between executing a given block of code and receiving the result. Speed can be roughly separated into two main blocks: CPU-bound and I/O-bound. 

Profiling our codebase revealed that certainly there were some CPU-bound issues (that’s a whole separate topic, cyscale, the Cython SCALE codec I wrote), but the vast majority of our speed issues were I/O-bound, which is to say we were waiting on network requests. 

Naturally, with my background in asyncio, I reached for that library, but it wasn’t so simple: we relied on a library called substrate-interface that was entirely synchronous, and did not adapt well to concurrency. I proposed a simple solution: I’ll just rewrite the library to be async-first, with sync compatibility. On the journey to the rewrite, I noticed a number of requests were being duplicated. This is, of course, the nature of needing a chain’s metadata to encode/decode the values you use in interacting with the chain, but wouldn’t it be nice to cache some of these?

## Two things people call "caching"

When someone says "just cache it," they usually mean one of two different things. The two get mixed up constantly, and that's where a lot of caching bugs come from.

**1\. Memoization.** Remember the result of a call keyed by its arguments, and return the stored value next time. You’ve likely used `functools.lru_cache`. It trades memory and freshness for fewer calls. The stored result sticks around, which is the point, and also the thing that bites you once the underlying value has moved on.

**2\. Request coalescing** (a.k.a. *single-flight*, *request collapsing*, or "thundering-herd prevention"). When N callers ask for the same thing *while a request is already in progress*, don't start N requests; let the first one run and hand its result to the other N−1. Go's `singleflight` package is the canonical example. The important part: it remembers *nothing* once the in-flight request resolves.

These get lumped together because both reduce the number of calls. But they have opposite relationships with *time*:

|                              | Memoization              | Coalescing                                 |
|:-----------------------------|:-------------------------|:-------------------------------------------|
| Lifetime of the stored value | until evicted (long)     | only while the call is in flight (instant) |
| Risk of returning stale data | yes                      | no                                         |
| Helps with                   | repeated calls over time | simultaneous calls right now               |

`CachedFetcher` does both at once, and it lets you turn either one off independently. That last part is the bit I actually want to talk about.

## The shape of it

The core is small enough to read in one sitting. (Async caching is only safe when the cached result is immutable, which is a luxury we usually have when dealing with blockchain data.)

```py
class CachedFetcher:
    def __init__(self, max_size, method, cache_key_index=0, cache_results=True):
        self._inflight: dict[Hashable, asyncio.Future] = {}
        self._method = method
        self._cache = LRUCache(max_size=max_size)
        self._cache_key_index = cache_key_index
        self._cache_results = cache_results

    async def __call__(self, *args, **kwargs):
        key = self.make_cache_key(args, kwargs)

        # (1) memoization: have we already got a finished answer?
        if self._cache_results and (item := self._cache.get(key)) is not None:
            return item

        # (2) coalescing: is an identical call already running? ride along.
        if key in self._inflight:
            return await self._inflight[key]

        # (3) we're the first. Register a future others can await, then do the work.
        loop = asyncio.get_running_loop()
        future = loop.create_future()
        self._inflight[key] = future
        try:
            result = await self._method(*args, **kwargs)
            if self._cache_results:
                self._cache.set(key, result)
            future.set_result(result)
            return result
        except Exception:
            self._inflight.pop(key, None)
            future.cancel()
            raise
        finally:
            self._inflight.pop(key, None)
            if not future.done():
                future.cancel()
```

Three gates, in priority order:

1. **The LRU.** A finished, remembered result short-circuits everything. This is the memoization half.  
2. **The in-flight table.** If someone is *currently* fetching this key, we `await` their `Future` instead of launching our own request. This is the coalescing half.  
3. **The cold path.** We're first: publish a `Future` into `_inflight` so concurrent callers (gate 2\) can find it, run the real method, fan the result out to everyone waiting, and store it.

The detail that matters is how long `_inflight[key]` lives. It's created right before `await self._method(...)` and deleted in the `finally`. So it exists for exactly the duration of the in-flight request, and not a tick longer.

## Two halves, two shelf lives

Look back at the table for a second. Memoization is risky because the value it keeps can outlive the truth it was based on. Coalescing doesn't have that problem; it never holds onto anything past the end of the request.

So what happens if you keep gate 2 and throw away gate 1?

You get a cache that **deduplicates simultaneous work but never serves a stale value**. Two calls in the same `asyncio.gather` collapse into one request. But a call twelve seconds later (average block time in Bittensor), long after the first resolved and the `Future` was popped, finds an empty in-flight table and an empty LRU, and does a fresh fetch, so it gets fresh data while still never paying for redundant concurrent work.

That's the `cache_results=False` mode:

```py
if self._cache_results and (item := self._cache.get(key)) is not None:
    return item
...
if self._cache_results:
    self._cache.set(key, result)
```

Flip the flag off and the LRU is never read or written. Coalescing keeps working, because it never relied on the LRU in the first place; it relies on the `Future`, which only exists while the request is in flight.

### The chaintip

Some values are stable forever once known (the hash of block \#4,000,000 will never change, so memoize it). Others are *defined* as "right now" and go stale on a timescale of seconds: the current chain head, the latest finalized block, the current block number.

For those, you want the best of both and the cost of neither:

```py
async def get_chain_head(self) -> str:
    return await self._cached_get_chain_head()

@cached_fetcher(cache_key_index=None, cache_results=False)
async def _cached_get_chain_head(self) -> str:
    ...  # one chain_getHead RPC
```

Now our opening `asyncio.gather` of three operations that each need the head fires **one** `chain_getHead`, not three, but the next time you ask, you get the *current* head. The deduplication window is exactly the concurrency window, which is exactly what "don't go stale" requires.

Note there's no TTL and no invalidation logic. The deduplication window is just the lifetime of the in-flight future, which is the request itself. That's why it can't serve stale data: there's nothing to go stale.

## Making it a method decorator

A standalone `CachedFetcher` is fine, but you want to write:

```py
@cached_fetcher(cache_key_index=None, cache_results=False)
async def _cached_get_chain_head(self): ...
```

That decorator hides two problems that are easy to get wrong:

- **Per-instance caches.** A class-level decorator must not share one cache across all instances (instance A would serve instance B's block hashes). The fix is a descriptor (`__get__`) that lazily builds one `CachedFetcher` *per instance*, stored in a `WeakKeyDictionary` so the cache doesn't keep dead instances alive.  
- **Not pinning the instance.** The fetcher holds a reference to the bound method, which references `self`. A `_WeakMethod` wrapper holds a weak ref to the instance (and stashes the signature for introspection) so garbage collection still works.

## Correctness corners

A few things the implementation gets right that are easy to get wrong:

- **A failed call doesn't poison the cache.** On an exception the in-flight `Future` is removed and canceled, so the next *new* caller starts a fresh request instead of inheriting the failure. Callers that were already coalesced onto that future all see the same exception, since they were riding the one request, and it failed, but nothing stale or broken is left behind for later.
- **The `finally` cleans up unconditionally.** However, the call ends, the key leaves `_inflight`. A leaked entry there would wedge that key forever, so this isn't optional.
- **The cache read compares against `None` on purpose.** Writing `if item := cache.get(key)` instead would re-fetch any falsy-but-valid cached value: an empty string, `0`, `False`. The `is not None` check keeps those legitimate results cached.

## How it compares to other available options

Before writing this, the obvious question is whether something off the shelf already does it. It helps to put the options on a grid along two axes: does the tool *memoize* (keep results around), and does it *coalesce* (collapse concurrent identical calls into one)?

|                            | Memoizes | Coalesces | Async |
|:---------------------------|:---------|:----------|:------|
| `functools.lru_cache`      | yes      | no        | no    |
| `async-lru` (`alru_cache`) | yes      | yes       | yes   |
| `aiocache` (`@cached`)     | yes      | no¹       | yes   |
| Go `singleflight`          | no       | yes       | n/a   |
| `CachedFetcher`            | optional | yes       | yes   |

¹ aiocache's decorator doesn't dedupe concurrent calls on its own; two simultaneous misses both run.

A few words on the closest neighbors.

**`async-lru`** is the one most people reach for, and it's good. `alru_cache` caches the in-flight task, so concurrent calls for the same key do share a single task (it coalesces), and it takes an optional `ttl`. Where it didn't fit was the *coalesce-but-don't-keep* case. It's built to retain results (hence "lru"), and there's no clean way to say "share concurrent work, but never hand a later caller a remembered value." You can shrink the TTL, but a TTL is a guess about how long a value stays true, and for something like the chain head the only correct guess is "as long as the request that's already running, and not one block longer."

**`aiocache`** is a different animal: a caching framework with pluggable backends (in-memory, Redis, Memcached) and TTLs. If you need a cache shared across processes, that's the tool to pick up. But its `@cached` decorator doesn't guard against the thundering herd by default: fire ten concurrent misses, and you get ten backend calls. Coalescing just isn't what it's for.

**Go's `singleflight`** is the spiritual sibling. It coalesces and does nothing else; it keeps no results. `CachedFetcher` with `cache_results=False` is basically `singleflight` for asyncio. The difference is that the same primitive can flip memoization back on for the keys where retention is correct (a block hash, given its number, is true forever), so you don't end up reaching for two different tools to handle two kinds of value.

So the gap here isn't "a better LRU." It's that none of the Python options let you pick coalescing *without* retention per method, and that's exactly the knob you want for "current"-style values.

## When to reach for it (and when not)

**Good fit:** idempotent, read-only async fetches whose results are immutable; especially anything that gets fanned out by higher-level composition you don't control. Coalescing-only mode (`cache_results=False`) for "current"-style values; full mode for stable-by-key values.

**Bad fit:** writes / anything with side effects; mutable results; values where you actually need a real TTL (then use a real TTL cache, since coalescing won't save you).

## Closing thought

`functools.lru_cache` taught a generation of Python devs that "caching" is one thing with one knob (`maxsize`). `CachedFetcher` is a small argument that it's really *two* things, and that separating them buys you something most caching libraries don't hand you out of the box: deduplication that can't serve a stale result, because there's nothing kept around to go stale.   
