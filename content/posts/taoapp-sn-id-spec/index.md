---
title: "Put Your Subnet's Story On Chain: The TAOAppv1 Identity Payload"
date: 2026-09-16T16:18:05+02:00
authors: ["thewhaleking"]
tags: ["bittensor", "taoapp", "open source"]
summary: "Subnet owners can now store a tagline, category, links and a full About page inside their on-chain identity. TAOApp renders it directly from chain, and the format is open for every other explorer and wallet to use."
cover:
  image: "cover.png"
  alt: "Bittensor Spec"
  relative: true
draft: false
---

If you run a Bittensor subnet, you have probably had this experience: you rename
your subnet, ship a new website, or pivot from one problem to another, and three
weeks later the explorers still show the old name, the old link, and a
description someone wrote from your GitHub README a year ago. You message a
Discord admin. Maybe it gets fixed. Maybe it gets fixed on one site and not the
others.

If you run an explorer, you have had the mirror image of that experience. We
have. Here is how TAOApp handled subnet categories until last week: a Google
Sheet. Someone filled it in by hand, a script uploaded it into our database, and
the Explorer read it back out. The script's author is no longer, the script was
deleted, and the sheet went stale. Half the rows were empty. Netuids got
deregistered and re-registered under new owners while the old category stayed
attached to the number. 

The About pages on subnet detail pages were the same story with more words.
Eleven of them, curated by hand, each one a small research project, each one
out of date the moment the subnet shipped something.

This is a data ownership problem, rather than a tooling one. The people who
know what a subnet is are the people who run it, and they had no place to put
that knowledge where every indexer could pick it up.

## The chain already has a slot for this

Subtensor stores a `SubnetIdentity` per subnet: name, GitHub repo, contact,
URL, Discord, description, logo URL, and a field called `additional`. Only the
owner coldkey can set it, through `setSubnetIdentity`. That is exactly the
authorization model we want: no registration with us, admin queue, undying love and 
trust in TAOApp. If you own the subnet, you own its description.

The `additional` field is a `Vec<u8>` capped at 1024 bytes by the runtime.
Nobody was using it for anything in particular. So we defined a format for it.

## What goes in

The payload is a small JSON document. Every key is optional.

| Key        | What it is                                                                                                                                        |
|------------|---------------------------------------------------------------------------------------------------------------------------------------------------|
| `tagline`  | One line under the subnet name, up to 140 characters.                                                                                             |
| `category` | Free text, up to 32 characters. The editor offers presets, but you can type your own.                                                             |
| `tags`     | Up to eight short labels.                                                                                                                         |
| `links`    | X, Telegram, docs, dashboard, whitepaper, Hugging Face, YouTube, LinkedIn, GitHub. All https.                                                     |
| `about`    | A full About page, see below.                                                                                                                     |

That last one is the point. A subnet's About page on TAOApp is now whatever
the owner wrote, rendered straight from chain. Our hand-curated pages are the
fallback for subnets that have not set one yet, not the source of truth.

### The About page

`about` is not a blob of prose. It is the same structure our curated pages
already had, so an owner-written page renders through the same component and
looks like it belongs. Every key is optional here too.

| Key                                           | What it is                                                                                                      |
|-----------------------------------------------|-----------------------------------------------------------------------------------------------------------------|
| `title`, `subtitle`                           | The page heading, 120 and 200 characters.                                                                       |
| `problem`, `solution`, `validators`, `miners` | Four sections of up to 3000 characters each: what you are solving, how, and what each side of the subnet does.  |
| `future`                                      | The roadmap. Up to 12 items of 300 characters. Start an item with `Title: ` and it renders as a bold label.     |
| `benchmark`                                   | A description, an https link, button text and a subtext. How do you measure the subnet, and where can I see it? |
| `team`                                        | Up to 10 people: name, a short description, X and LinkedIn links.                                               |
| `read_more`                                   | Up to 10 further-reading links: title, subtitle, https url.                                                     |

Limits are in Unicode characters and enforced by the writer. A reader that
finds something longer truncates or drops it rather than failing.

## Fitting an About page into 1024 bytes

A four-paragraph About page with a roadmap, a team list and links is a few
kilobytes of JSON. The budget is 1024 bytes, and nine of those go to a version
prefix. This is where the format earns its keep.

```
additional = "TAOAppv1:" + base64url( deflate_raw( json, dictionary=DICTIONARY_V1 ) )
```

Three decisions:

**Compression with a preset dictionary.** Raw DEFLATE gets a typical About
page down to around 700 bytes, which fit six of our eleven curated pages.
DEFLATE with a preset dictionary, a 26 KB blob of the words and JSON
structure these documents actually contain, fit ten. A full page now encodes
to 350 to 450 bytes. The dictionary is frozen and part of the wire format: its
SHA-256 is pinned in the spec, and changing one byte of it would make every
payload already on chain undecodable. A new dictionary means a new major
version and a new prefix.

**Text, not bytes.** Raw bytes would give us a third more room. We passed. Too
many pipelines between the chain and a screen decode `Vec<u8>` as UTF-8 when
it happens to be valid and as hex when it does not, and a compressed blob
would get mangled by at least one of them. A base64url string survives all of
them unchanged, and a human can still see the `TAOAppv1:` prefix and know what
they are looking at.

**A plain form for hand authoring.** If you would rather not compress, a JSON
object with `"apiVersion": "TAOAppv1"` in it is also a valid payload. No size
advantage, but you can write it in a text editor and pass it to btcli.

One thing that bit us during testing and is now a rule in the spec: DEFLATE
output is not unique. JavaScript's pako and Python's zlib produce different
compressed bytes for the same input and the same dictionary, and both decode
to the same JSON. So tools must compare payloads by decoded content, never by
the encoded string. TAOApp's own editor submits the chain's existing bytes when
your decoded content has not changed, so you do not pay for a transaction that
does nothing.

## Rules for anyone reading it

The spec is written so that a reader can be strict about safety and lenient
about everything else:

- Every string is untrusted text. Render it as text, never as HTML or
  Markdown. All URLs must be `https:` or they are dropped.
- Unknown keys are ignored. An invalid value is dropped and the rest of the
  document kept. One bad link must not blank a page.
- An unknown major version, or anything that does not decode, is treated as
  opaque owner prose and shown as such. The `description` field keeps its
  plain-text meaning for wallets that know nothing about any of this.
- Trim whitespace first. On-chain values often end in a newline.

## Where to find it on TAOApp

**Setting it.** Go to [tao.app/subnet-admin](https://www.tao.app/subnet-admin)
and open Subnet identity. Connect the coldkey that owns your subnet and the
form loads what is on chain today. Fill in the tagline, pick a category or type
your own, add links, write the About page. A capacity meter shows how much of
the 1024 bytes you have used as you type. Sign in the browser, or export the
extrinsic and submit it with btcli from a machine you trust more than a browser
tab. We also present the raw hex for using directly with Polkadot.JS if you'd
prefer to go that route 👴🏼.

**Seeing it.** The tagline and category chips appear in the subnet header, the
links next to them, and the About tab renders your page. The Explorer's
category filter is built from what owners have set, with our old list as a
fallback for subnets that have not.

**Reading it without decoding.** The API serves the decoded document:

```
GET https://api.tao.app/api/beta/subnets/owner-content?netuid=<N>
```

It returns the payload as JSON, or 404 when the subnet has none.

**Writing it without us.** The whole struct is replaced on every write, so pass
every field:

```
btcli subnets set-identity --netuid <N> --additional-info 'TAOAppv1:…' \
  --subnet-name '…' --github-repo '…' --subnet-contact '…' --subnet-url '…' \
  --discord '…' --description '…' --logo-url '…'
```

## The spec is open

The format lives at
[github.com/latent-to/TAOApp-specs](https://github.com/latent-to/TAOApp-specs/tree/master/taoapp-v1)
under Apache 2.0: the spec, the frozen dictionary with its checksum, eight test
vectors that any conforming decoder must reproduce, and complete encoder and
decoder samples in JavaScript and Python using only pako and the standard
library.

We wrote it because we wanted the data, but there is nothing TAOApp-specific in
it beyond the prefix. If you build a wallet, an explorer, a dashboard, or a bot
that shows subnet information, you can read these payloads today, and your
users get the same owner-written content ours do. The best outcome for this
format is that it stops being ours.
