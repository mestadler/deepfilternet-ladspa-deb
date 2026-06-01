# TODO

- [x] **CI — automatic .deb rebuild on upstream releases**
  Implemented in `.github/workflows/build.yml`:
  - Triggers on push to `main`, PRs, weekly schedule (Mondays 03:00 UTC), and `workflow_dispatch`
  - Checks out the repo with submodules
  - Installs Rust toolchain with Cargo caching
  - Runs `./scripts/build-deb.sh`
  - Uploads the resulting `.deb` as a build artifact (90-day retention)
  - Creates a GitHub Release when triggered on a tag push

- [ ] **Push to remote** — no remote configured yet; create a GitHub repo and add as origin
