# TODO

- [ ] **CI — automatic .deb rebuild on upstream releases**
  Set up a GitHub Actions workflow (or equivalent) that:
  - Triggers periodically (e.g. weekly) or on demand via `workflow_dispatch`
  - Checks out the repo with submodules
  - Runs `./scripts/build-deb.sh`
  - Uploads the resulting `.deb` as a build artifact
  - Optionally creates a GitHub Release when a new upstream tag is detected
