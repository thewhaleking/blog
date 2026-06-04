#!/usr/bin/env bash
# Cloudflare Pages build entrypoint (set the project's build command to
# `bash build.sh`).
#
# Production builds (the master branch) use the canonical baseURL from
# hugo.toml — https://blog.latent.to/. Every other branch is a preview
# deployment and is built with its own *.pages.dev URL, so internal links stay
# on the preview instead of bouncing to the production domain.
#
# CF_PAGES_BRANCH and CF_PAGES_URL are injected by Cloudflare Pages. When unset
# (e.g. running this locally) we fall back to the hugo.toml baseURL.
set -euo pipefail

if [ "${CF_PAGES_BRANCH:-}" = "master" ] || [ -z "${CF_PAGES_URL:-}" ]; then
  hugo --gc --minify
else
  hugo --gc --minify --baseURL "${CF_PAGES_URL}/"
fi
