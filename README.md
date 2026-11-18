# BD Himes Blog

Live: [blog.bdhimes.com](https://blog.bdhimes.com)

A static engineering blog. Posts are Markdown added via pull requests; merges to
`master` build the site with [Hugo](https://gohugo.io) and publish it to
GitHub Pages. No database, no server, no `node_modules`.

Authors are GitHub usernames. Display names, avatars, and bios live in
`data/authors.yaml`, kept in sync with GitHub by a scheduled workflow (see
[One-time setup](#one-time-setup)) — so the build stays offline and there are no
author records to maintain by hand.

```
PR adds content/posts/<slug>/index.md (+ images)
  -> "Build check" workflow validates the PR builds
  -> merge to master
  -> "Deploy to GitHub Pages" workflow builds + publishes
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
| `.github/workflows/deploy.yml`          | Builds `master` and publishes it to GitHub Pages                                           |
| `.github/workflows/ci.yml`              | Build check on every PR                                                                    |
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

1. **Settings → Pages → Build and deployment → Source**: `GitHub Actions`.
2. **Settings → Pages → Custom domain**: `blog.bdhimes.com`, then enable
   **Enforce HTTPS** when the certificate is ready.
3. DNS for `bdhimes.com`: a `CNAME` record, `blog` → `thewhaleking.github.io`.
4. **Settings → Actions → General → Allow GitHub Actions to create and approve
   pull requests**: enable, so the author refresh workflow can open its PR.

The deploy workflow (`.github/workflows/deploy.yml`) builds with the Hugo
version pinned in `HUGO_VERSION` and with `baseURL` from `hugo.toml`. Keep
`baseURL` equal to the `https://` custom domain.

The build needs no GitHub token: author profiles are read from the committed
`data/authors.yaml`, not fetched. That file is refreshed out-of-band by the
**Refresh author profiles** workflow (`.github/workflows/refresh-authors.yml`),
which runs weekly (and on demand via *Actions → Run workflow*), regenerates the
data from the GitHub API, and opens a PR with any changes. The workflow uses the
Action's built-in `GITHUB_TOKEN`, so there is no secret to manage.
