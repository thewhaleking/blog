# Latent Engineering Blog

A static engineering blog. Posts are Markdown added via pull requests; merges to
`master` build the site with [Hugo](https://gohugo.io) and publish it to GitHub
Pages. No database, no server, no `node_modules`.

Authors are GitHub usernames — display names, avatars, and bios are pulled from
GitHub at build time, so there are no author records to maintain.

```
PR adds content/posts/<slug>/index.md (+ images)
  -> PR build check (.github/workflows/ci.yml)
  -> merge to master
  -> build + deploy (.github/workflows/deploy.yml) -> GitHub Pages
```

## Writing a post

See [CONTRIBUTING.md](CONTRIBUTING.md). The short version:

```bash
hugo new content/posts/my-post/index.md   # edit it, set draft: false
hugo server -D                            # preview at localhost:1313
# commit on a branch and open a PR
```

## Layout

| Path | What |
| --- | --- |
| `content/posts/<slug>/` | One post per folder: `index.md` + its images |
| `archetypes/posts.md` | Frontmatter template for `hugo new` |
| `layouts/_partials/github_user.html` | Fetches a GitHub profile (name/avatar/bio) at build time |
| `layouts/_partials/author.html` | Override: author byline → linked author pages |
| `layouts/authors/term.html` | Author archive page (GitHub profile header + their posts) |
| `assets/css/extended/author.css` | Small styling for the author profile header |
| `themes/PaperMod` | Theme (git submodule) |
| `hugo.toml` | Site config: title, taxonomies (tags, authors), menu |
| `.github/workflows/` | `ci.yml` (PR build check), `deploy.yml` (publish) |

## Local development

```bash
brew install hugo                          # extended build
git submodule update --init --recursive    # fetch the theme
hugo server -D                             # dev server with drafts
hugo --gc --minify                         # production build into public/
```

## One-time setup

In the GitHub repo: **Settings → Pages → Build and deployment → Source =
"GitHub Actions"**. The deploy workflow then builds with the URL GitHub assigns
the site (passed via `--baseURL`), so production links are always correct — no
need to keep `baseURL` in `hugo.toml` in sync. Note: while **Pages visibility is
Private**, GitHub serves the site from a randomized `*.pages.github.io` domain
(only repo members can view it); switch visibility to Public for the stable
`latent-to.github.io/blog/` URL.
