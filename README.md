# my-ai-observe-notes

GitHub Pages publication shell — see [index page](https://ilto-matoes.github.io/my-ai-observe-notes/) (once deployed).

This repository hosts a static site built with MkDocs. The actual source notes live in a separate private repository; only curated, desensitized articles are published here.

## Tech stack

- [MkDocs](https://www.mkdocs.org/) with `material` theme
- GitHub Actions for automatic build + deploy
- `gh-pages` style deployment via `actions/deploy-pages`

## Layout

```
.
├── mkdocs.yml            # site config
├── requirements.txt      # python deps
├── docs/                 # published content (curated)
│   ├── index.md
│   └── articles/         # blog posts
├── .github/workflows/    # CI/CD
└── scripts/              # helper scripts (sync from private source)
```

## Status

🚧 Initial setup in progress.
