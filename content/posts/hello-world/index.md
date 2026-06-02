---
title: "Hello, World"
date: 2026-06-02
authors: ["thewhaleking"]
tags: ["meta", "engineering"]
summary: "Why we built this blog the way we did — Markdown in, static site out."
draft: false
---

Welcome to the Latent engineering blog.

This is a seed post that proves the whole pipeline end to end: a Markdown file and
its images live together in one folder, a pull request adds them, and merging to
`master` builds and deploys the site to GitHub Pages — no database, no server, no
`node_modules`.

## How it works

- Posts are **Markdown**, authored in pull requests.
- Each post is a *page bundle* — a folder containing `index.md` plus any images.
- **Tags** and **authors** are driven by frontmatter and rendered as their own pages.
- A GitHub Action builds the static site with [Hugo](https://gohugo.io) and publishes it.
- Images go in the post's own folder and are referenced relatively, e.g. `![alt](diagram.png)`.

## Adding your own post

See [`CONTRIBUTING.md`](https://github.com/latent-to/blog/blob/master/CONTRIBUTING.md)
for the full workflow. The short version:

```bash
hugo new content/posts/my-post/index.md
# write your post, drop images in the same folder, set draft: false
git checkout -b my-post && git add . && git commit -m "Add my post"
# open a PR
```

That's it. Happy writing.
