# TODO

- [x] **CI — automatic .deb rebuild on upstream releases**
  Implemented in `.github/workflows/build.yml`:
  - Triggers on push to `main`, PRs, weekly schedule (Mondays 03:00 UTC), and `workflow_dispatch`
  - Checks out the repo with submodules
  - Installs Rust toolchain with Cargo caching
  - Runs `./scripts/build-deb.sh`
  - Uploads the resulting `.deb` as a build artifact (90-day retention)
  - Creates a GitHub Release when triggered on a tag push

- [x] **Push to remote** — `git@github.com:mestadler/deepfilternet-ladspa-deb.git`

- [ ] **GPU-accelerated inference via OpenVINO** (low priority)
  The current build uses `tract` (pure-Rust, CPU-only). On an i7-1355U CPU inference is already fast enough for real-time audio. If CPU headroom becomes an issue:
  - Fork the LADSPA crate to use `deepfilter-rt` (ONNX Runtime via `ort`) instead of `deep_filter` (tract)
  - Enable OpenVINO EP for Xe-LP iGPU offloading
  - Package as a separate `.deb` variant (e.g. `libdeep-filter-ladspa-openvino`)
  - Significant upstream divergence — only worth pursuing if tract latency becomes a bottleneck
