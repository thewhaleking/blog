# Contributing a post

Posts are Markdown, added via pull request. When your PR merges to `master`,
Cloudflare Pages builds the site and publishes it. There is no database and no
server — just static files.

## Prerequisites

Install Hugo **extended** (the site uses it):

```bash
brew install hugo   # macOS
```

Clone with submodules so the theme is present:

```bash
git clone --recurse-submodules git@github.com:latent-to/blog.git
# already cloned? then:
git submodule update --init --recursive
```

## Write a post

Each post is a *page bundle*: a folder under `content/posts/` containing
`index.md` plus any images it uses, so the post and its assets travel together.

```bash
hugo new content/posts/my-post/index.md   # scaffolds frontmatter from archetypes/posts.md
```

Then edit `content/posts/my-post/index.md`:

```yaml
---
title: "My Post Title"
date: 2026-06-02
authors: ["thewhaleking"]        # one or more GitHub usernames (see "Authors" below)
tags: ["go", "infra"]            # creates/links /tags/<tag>/ pages
summary: "One-line description shown in listings and search results."
cover:                           # optional; drop the image in this folder
  image: "cover.png"
  alt: "Describe the image"
  relative: true                 # required: makes og:image/twitter:image resolve inside this folder
draft: false                     # MUST be false to publish
---

Your content here.
```

- Drop images **in the same folder** and reference them relatively:
  `![alt](diagram.png)`.
- `draft: true` posts are excluded from the published site (preview them locally
  with `hugo server -D`).

## Authors

Authors **are GitHub usernames** — just put your handle(s) in `authors`. Display
names, avatars, and bios come from `data/authors.yaml`, so each author gets an
archive page at `/authors/<username>/` with their profile and all their posts.
There are no author files to maintain by hand.

```yaml
authors: ["thewhaleking"]            # single author
authors: ["thewhaleking", "octocat"] # co-authored
```

`data/authors.yaml` is regenerated from the GitHub API by a scheduled workflow
that opens a PR with any changes — the site build never calls GitHub. A
brand-new author may show as the raw username until that refresh PR merges; to
populate it immediately, run **Actions → Refresh author profiles → Run
workflow** (or `python scripts/refresh_authors.py` locally) and merge the PR.

## Preview locally

```bash
hugo server -D     # http://localhost:1313  (-D includes drafts)
```

Check your post renders, images load, and your tag/author pages look right.

## Open the PR

```bash
git checkout -b my-post
git add .
git commit -m "Add post: My Post Title"
git push -u origin my-post
# open a PR against master
```

Cloudflare Pages builds your branch and posts a preview deployment on the PR.
**If the build fails, fix the reported error** (usually bad frontmatter) and push
again; use the preview URL to check your post renders before merging. Once merged,
Cloudflare publishes it to production automatically.
