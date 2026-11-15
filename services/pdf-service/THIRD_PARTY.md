# Third-party material bundled in pdf-service

## Fonts (`fonts/`)

The renderer embeds subsets of these fonts in every PDF it writes; they are compiled into the binary
(`include_bytes!` in `crates/adapters/src/render.rs`) and never loaded from the network or from a caller.

| File | Font | Licence | Source |
|---|---|---|---|
| `fonts/Roboto-Regular.ttf` | Roboto Regular (Christian Robertson, Google) | Apache License 2.0 (`fonts/LICENSE-Roboto.txt`) | Flutter SDK `bin/cache/artifacts/material_fonts` (the copy the Flutter toolchain of `apps/web` ships) |
| `fonts/Roboto-Bold.ttf` | Roboto Bold | Apache License 2.0 (`fonts/LICENSE-Roboto.txt`) | same |

SHA-256 of the committed files:

```
79e851404657dac2106b3d22ad256d47824a9a5765458edb72c9102a45816d95  fonts/Roboto-Regular.ttf
7d0b991ee3e0be7af01ad7ea8cd2beea6c00a25e679a0226b6737f079aafff86  fonts/Roboto-Bold.ttf
```

Roboto covers the Latin letters of Spanish, English and Indonesian (á é í ó ú ü ñ ¿ ¡, the en dash, "…", "×").

## Crates

The Rust dependencies and their licences are listed by `cargo deny list` (allowed licences: `deny.toml`); the image's
CycloneDX SBOM (`scripts/sbom.sh`) lists what the image ships.
