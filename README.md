# DeepFilterNet LADSPA Plugin — Debian Packaging

Build system and guide for packaging [DeepFilterNet](https://github.com/Rikorose/DeepFilterNet)'s
LADSPA noise‑reduction plugin as a Debian `.deb` package.

The resulting `.deb` can be installed on Debian Sid / Debian 13 to add
neural‑network voice denoising to **Easy Effects**.

## Quick Start

```bash
# Build the .deb
./scripts/build-deb.sh

# Install
sudo dpkg -i output/libdeep-filter-ladspa_0.5.7-1_amd64.deb
```

After installation the plugin appears in Easy Effects as
**DeepFilterNet (noise suppression)**.

## Full Guide

For a complete walkthrough with prerequisites, troubleshooting, and optimisations see
[DeepFilterNetNoiseReductiontoEasyEffectsonDebianSid.md](./DeepFilterNetNoiseReductiontoEasyEffectsonDebianSid.md).

## Files

| Path | Purpose |
|---|---|
| `scripts/build-deb.sh` | Build script — compiles the Rust crate and packages the .deb |
| `deepfilternet-src/` | Upstream DeepFilterNet source (git sub‑tree) |
| `output/` | Built `.deb` artifacts (gitignored) |
| `logs/` | Build logs (gitignored) |

## License

MIT — see [LICENSE](./LICENSE).
The upstream DeepFilterNet source ships under its own (MIT / Apache‑2.0 / GPL‑3.0).
