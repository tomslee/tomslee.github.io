# CLAUDE.md

Guidance for Claude Code working in this repository.

## Project Overview

Personal website and blog for Tom Slee, published via GitHub Pages from the **`gh-pages` branch**. Source `.qmd` files live on `main`; Quarto renders them (default output `_site/`) and `quarto publish gh-pages` pushes the rendered HTML to the `gh-pages` branch.

## CRITICAL: Publishing Workflow

The site is served from the **`gh-pages` branch** (GitHub Pages source: `gh-pages` / root). Source `.qmd` files and `_freeze/` live on `main`; rendered HTML lives **only** on `gh-pages`. Publication is manual — there is no CI/CD.

To publish:

1. Work on a feature branch (never directly on `main` for new content)
2. Land the source changes on `main`
3. Run `quarto publish gh-pages` — renders the site to `_site/` (honoring `freeze: auto`, so unchanged pages are not re-executed) and pushes the output to the `gh-pages` branch via a git worktree
4. Commit the source `.qmd` and updated `_freeze/` to `main`

Do not push `main` or run `quarto publish` without explicit user confirmation. Always work on a branch when adding or substantially changing content.

Notes:
- The rendered site is **not** committed to `main`. `docs/` and `_site/` are gitignored; `quarto publish gh-pages` manages the `gh-pages` branch on its own.
- GitHub Pages uses the legacy branch-based build (there is no GitHub Actions workflow). Pushing `main` does **not** trigger a publish — only `quarto publish gh-pages` updates the live site.

## Content Areas

- `posts/` — Archive of blog posts from 2005–2021. Do not add new posts here.
- `essays/` — Curated essays. Date-prefixed subdirectories (`YYYY-MM-slug/`), each with `index.qmd`.
- `uncertainties/` — Working documents and data explorations. Same directory convention.
- All three areas are listed via Quarto listing pages. **Do not use `draft: true` while developing** — in Quarto 1.8, `draft: true` completely suppresses HTML rendering, producing an empty stub. To hide a page from listings during development, add it to the `!` exclude list in `_quarto.yml` instead, then remove the exclusion when ready to publish.

## Ridehail Database Access

The interactive Toronto ridehail dashboard is a **separate site** (linked from the navbar as "Ridehail Dashboard", <https://tomslee.github.io/ridehail-toronto/>), not a page in this repo. The notes below apply to any in-repo `uncertainties/` page that queries the data directly.

Ridehail databases live in the sibling directory `~/src/ridehail-toronto/duckdb/`:

| Database | Contents |
|---|---|
| `toronto_opendata.duckdb` | City of Toronto open data: `trips` (aggregated OD-zone by hour/ward), `summary_stats` (daily fleet metrics), `operating_hours` (per-vehicle hourly stats) |
| `toronto.duckdb` | Full FOIA dataset — 123M raw trip records (8.2GB, slow to query) |
| `opendata.duckdb` | Open data copy |

Reference from `.qmd` files using:
```r
db_path <- file.path(Sys.getenv("HOME"), "src/ridehail-toronto/duckdb/toronto_opendata.duckdb")
con <- DBI::dbConnect(duckdb::duckdb(), dbdir = db_path, read_only = TRUE)
```

**freeze: auto** is configured in `_quarto.yml` and `_freeze/` is committed to git. This means database queries only run when the source `.qmd` changes. Always commit `_freeze/` after rendering (the rendered HTML goes to `gh-pages` via `quarto publish`, not to `main`).

## Quarto Conventions

Standard frontmatter for an `uncertainties/` page:

```yaml
---
title: "Page title"
author: "Tom Slee"
date: last-modified
date-format: long
published-title: Last updated
categories:
  - Uncertainties
  - Ridehail
description: >
    One-sentence description shown in the grid listing.
toc: true
toc-title: Contents
number-sections: true
callout-appearance: simple
image: some-preview-image.png
format:
  html:
    title-block-banner: DarkCyan
---
```

R packages: use `library()` directly — `duckdb`, `dplyr`, `ggplot2`, `lubridate`, `scales` are all available. Use `DBI::dbDisconnect(con)` after queries.

## What to Commit After Rendering

Commit to `main`:
- `uncertainties/<slug>/index.qmd` (or `essays/...`) — the source
- `_freeze/<area>/<slug>/` — frozen execution results (prevents re-running queries on the next render/publish)

Do **not** commit rendered HTML to `main` — `quarto publish gh-pages` renders to `_site/` and pushes it to the `gh-pages` branch. Without `_freeze/`, the next render re-executes all code (re-queries the database).
