---
title: "The Importance of a Benchmark"
date: 2026-07-30T20:33:17+02:00
authors: ["thewhaleking"]
tags: ["engineering"]
summary: "Understanding what a benchmark truly shows"
cover:
   image: "cover.jpg"
   alt: "Goodhart's Law"
draft: false
---

"According to their benchmarks, libzk is 400x faster than librg. Let's switch to libzk."

You've heard this from colleagues, you've read this on Xitter, and you've probably said it yourself. Of course you did,
why would you use this slow thing when there's a table clearly showing that fast thing is faster?

Apple has been a meme for years for their yearly WWDC benchmarks depicting charts that show marginal performance gains,
but displayed in ways to exaggerate the improvements, and recently Anthropic has joined the club. While, to the discerning 
viewer, these can give a bit of a laugh, there's a very real reason they produce these: people buy things when the "data"
shows it's a massive improvement. 

It's worth noting that while chart manipulation is an important part of understanding benchmarks, the topic I want to
discuss here is the numbers themselves, and what they mean.

## Latent 

Take this table for example:
```
  ┌─────────────────────────────────────────────────────┬─────────┬────────────┬─────────┐
  │                      Operation                      │   asi   │ v11 (Rust) │  ratio  │
  ├─────────────────────────────────────────────────────┼─────────┼────────────┼─────────┤
  │ build 10k storage keys                              │ 19ms    │ 8.5ms      │ 2.2x    │
  ├─────────────────────────────────────────────────────┼─────────┼────────────┼─────────┤
  │ decode 10k Account values                           │ 268ms   │ 14ms       │ ~20x    │
  ├─────────────────────────────────────────────────────┼─────────┼────────────┼─────────┤
  │ decode 1000-entry map page (Account / Keys / Bonds) │ 13–29ms │ 0.7–1.8ms  │ 15–25x  │
  └─────────────────────────────────────────────────────┴─────────┴────────────┴─────────┘
```

An important part of what we do at Latent is publish our open-source libraries. Recently, with the release of Bittensor
SDK v11, there was a switch from using our [async-substrate-interface](https://github.com/latent-to/aio-substrate-interface) package
internally in the SDK to using a Rust layer instead. As a substantial part of our internal tooling was built on 
`async-substrate-interface`, we were naturally keen to determine whether switching to bittensor SDK v11 would make sense
for us, as it would be a package we would no longer have to maintain. The above chart shows a **substantial** speedup 
(up to 25x!), and so the answer is clear: we should switch.

However, that doesn't paint the full picture. That's a substantial increase in speed for _decoding_. ASI uses [cyscale](https://github.com/latent-to/cyscale),
a Cython-powered SCALE decoder for encoding/decoding. Querying a chain involves a lot more than just the decoding of the
values, and so it's important to see what it means in a real-world situation where we would actually obtain this data from
the chain, and thus you have part two of the table:

```
  ┌─────────────────────────────────────────────────────┬─────────┬────────────┬─────────┐
  │ e2e query 10k accounts                              │ 4.1s    │ 4.5s       │ ~parity │
  ├─────────────────────────────────────────────────────┼─────────┼────────────┼─────────┤
  │ e2e get_block                                       │ ~0.3s   │ ~0.28s     │ ~parity │
  └─────────────────────────────────────────────────────┴─────────┴────────────┴─────────┘
```

Well, now the decision to switch isn't so cut-and-dry. The pros and cons chart is now centred around maintainability/effort
on our part, eliminating the speed aspect altogether.  Now, to be fair, async-substrate-interface 
(now renamed aio-substrate-interface) v3.0 is releasing in the coming weeks, which strips away a lot of backwards
compatibility (that existed to make it usable as the backbone of the bittensor SDK and btcli), and allows us room for
various speedups (especially within cyscale).

## Benchmarks In Life

I'm a wildlife photographer in my free time (what little there is of it). Within photography, two of the major negatives
that photographers obsess over are pixel peeping and noisy photos, and they're closely related.

Pixel peeping refers to zooming as far in to a photo as you can, and ensuring that every pixel is perfectly clear:

![A pixelated city skyline](pixelated-city.png)

Image noise is random variation of brightness or color information in images, often looking "gritty":

![Noisy photo of a white-rumped swift](noisy-white-rumped-swift.jpg)

As a result, many photographers check new camera specs, and annoy their friends: 
- "How many MP is this sensor? My photos won't look so pixelated with more megapixels!"
- "This prime lens goes to f/1.2! I can shoot in lower light!"
- "Stand perfectly still! This evening shot needs to be at ISO 100 or else it'll be noisy!"

With all of these scenarios, we must ask the same benchmark question: does it matter in the real world?

- If your photos are 5x7" printouts, will you ever notice the difference between a 50MP and a 60MP sensor?
- Is that f/1.4 to f/1.2 upgrade worth the $2000 price difference?
- Will any of your Instagram followers notice the difference between ISO 100 and ISO 400 on your 24-hour story?


## Targeted Benchmarks

Many libraries and programs contain at least a handful of parts which are not optimized as much as they could be. This
is usually because those specific parts don't matter much for the overall speed/readability/maintainability of the overall
piece of software. Picture this: an initialization check that runs for roughly 5ms at the beginning of a several-second-long
query. Stripping this of its checks might "optimize" this down to 20µs. That's a 250x speed increase! If you're looking
market your "fast" startup, you can show that your startup time is 250x faster, ignoring the fact that the initialization
check was important and did not constitute any substantial portion of the overall run time. A good programmer would not 
do this, but a good marketer would. Keep these in mind, as they are widespread.

Think of a benchmark like you think of a unit test: it tests (or in this case times) one specific thing. Just as a 
passing unit test does not mean the program is without bugs, so too does a speedy benchmark not necessarily mean that a
program is faster than another, in real-world scenarios.


## Conclusion

Benchmarks are highly useful, but they must be correctly targeted and should be used as only part of what shows a full
picture. One benchmark alone is usually not a good example of the overall speed of a program.

With benchmarks, it can be easy to lose the forest for the trees. After all, the trees have **200x** painted on them in 
a bold font, and at the end of the day, as an engineer it is up to you to make the right decision for your specific use
case. Ensure the benchmark shows the full picture, and you will see a tangible benefit that outweighs the cost of a 
refactor before jumping on it. 

Side note: though not yet released, in cyscale 0.7.0 and asi 3.0, the decoding difference has gone down to about 1.5x.
