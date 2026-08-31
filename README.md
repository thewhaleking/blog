# Latent Engineering Blog

Live: [blog.latent.to](https://blog.latent.to)

A static engineering blog. Posts are Markdown added via pull requests; merges to
`master` build the site with [Hugo](https://gohugo.io) and publish it to
Cloudflare Pages. No database, no server, no `node_modules`.

Authors are GitHub usernames. Display names, avatars, and bios live in
`data/authors.yaml`, kept in sync with GitHub by a scheduled workflow (see
[One-time setup](#one-time-setup)) — so the build stays offline and there are no
author records to maintain by hand.

```
PR adds content/posts/<slug>/index.md (+ images)
  -> Cloudflare Pages builds a preview deployment for the PR
  -> merge to master
  -> Cloudflare Pages builds + publishes production
```

## Writing a post

See [CONTRIBUTING.md](CONTRIBUTING.md). The short version:

```bash
hugo new content/posts/my-post/index.md   # edit it, set draft: false
hugo server -D                            # preview at localhost:1313
# commit on a branch and open a PR
```

## Layout

| Path                                    | What                                                                                       |
|-----------------------------------------|--------------------------------------------------------------------------------------------|
| `content/posts/<slug>/`                 | One post per folder: `index.md` + its images                                               |
| `archetypes/posts.md`                   | Frontmatter template for `hugo new`                                                        |
| `layouts/_partials/github_user.html`    | Resolves a GitHub profile (name/avatar/bio) from `data/authors.yaml`                       |
| `layouts/_partials/author.html`         | Override: author byline → linked author pages                                              |
| `layouts/authors/term.html`             | Author archive page (GitHub profile header + their posts)                                  |
| `assets/css/extended/author.css`        | Small styling for the author profile header                                                |
| `data/authors.yaml`                     | Baked-in author profiles (generated — don't hand-edit)                                     |
| `scripts/refresh_authors.py`            | Regenerates `data/authors.yaml` from the GitHub API                                        |
| `.github/workflows/refresh-authors.yml` | Runs the refresh script weekly; opens a PR with changes                                    |
| `build.sh`                              | Cloudflare build entrypoint: canonical baseURL on `master`, per-deployment URL on previews |
| `themes/PaperMod`                       | Theme (git submodule)                                                                      |
| `hugo.toml`                             | Site config: title, taxonomies (tags, authors), menu, `baseURL`                            |

## Local development

```bash
brew install hugo                          # extended build
git submodule update --init --recursive    # fetch the theme
hugo server -D                             # dev server with drafts
hugo --gc --minify                         # production build into public/
```

## One-time setup

In the Cloudflare dashboard: **Workers & Pages → Create → Pages → Connect to
Git**, pick this repo, and set:

| Setting                | Value                                                    |
|------------------------|----------------------------------------------------------|
| Build command          | `bash build.sh`                                          |
| Build output directory | `public`                                                 |
| Environment variables  | `HUGO_VERSION` = the Hugo extended version to build with |

`build.sh` builds production (the `master` branch) with the canonical `baseURL`
from `hugo.toml`, and every preview branch with its own `*.pages.dev` URL — so
preview links stay on the preview instead of jumping to the production domain.

The build needs no GitHub token: author profiles are read from the committed
`data/authors.yaml`, not fetched. That file is refreshed out-of-band by the
**Refresh author profiles** workflow (`.github/workflows/refresh-authors.yml`),
which runs weekly (and on demand via *Actions → Run workflow*), regenerates the
data from the GitHub API, and opens a PR with any changes. The workflow uses the
Action's built-in `GITHUB_TOKEN`, so there's no secret to manage — but the repo
setting **Settings → Actions → General → Allow GitHub Actions to create and
approve pull requests** must be enabled for it to open the PR.

Cloudflare clones submodules automatically, so the PaperMod theme is pulled in.
It deploys `master` as production and every PR as its own preview URL (posted as
a check on the PR). Keep `baseURL` in `hugo.toml` pointed at the production
domain (your `*.pages.dev` subdomain or a custom domain mapped in the Pages
project) so absolute links and feeds are correct.
