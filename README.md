# tautulli

Tautulli on the shared [alpine-base](https://github.com/Rake-Pro/alpine-base) image, built in-house from the upstream release.

```
ghcr.io/rake-pro/tautulli
```

## Tags / releases

| Tag | Meaning |
| --- | --- |
| `X.Y.Z` | Immutable release, built from git tag `vX.Y.Z` |
| `X.Y` | Latest patch of that minor |
| `latest` | Latest release |
| `<upstream-version>` | The exact upstream Tautulli version baked into that release (currently `2.18.2`) |
| `sha-<short>` | Commit the image was built from |

- `dev` is the integration branch (default); `ci.yml` builds, smoke-tests and Trivy-scans on every push and PR.
- `version-check.yml` polls upstream daily and opens a PR into `dev` bumping the pinned `VERSION` build arg.
- `sync-main.yml` opens a promotion PR from `dev` to `main`. Merging it (merge commit) mints the next patch tag and `release.yml` builds, scans and pushes the image. A fixable CRITICAL finding blocks the push.
- Label the promotion PR `release:minor` or `release:major` to change the bump.
- `trivy-rescan.yml` re-scans the released image weekly (CRITICAL+HIGH) so CVEs disclosed after release still surface.
- Dependabot bumps the base image digest and the GitHub Actions weekly.
- Pin `X.Y.Z` in deployments; `latest` is a convenience pointer.

## Image facts

| Item | Value |
| --- | --- |
| Base | `ghcr.io/rake-pro/alpine-base` (Alpine, patched weekly) |
| Init | `catatonit` as PID 1 |
| User | `65534:65534` from the first process (no s6, no privilege drop, no added capabilities) |
| Data | `/config` (config.ini, tautulli.db, logs, backups) |
| Port | `8181` |
| Upstream | <https://github.com/Tautulli/Tautulli> |
| Upstream version | `2.18.2` (build arg `VERSION`) |
| Platform | linux/amd64 |

## Run

```
docker run -d --name tautulli \
  -p 8181:8181 \
  -v /path/to/config:/config \
  ghcr.io/rake-pro/tautulli:latest
```

- The `/config` mount must be writable by uid 65534 (`chown -R 65534:65534 /path/to/config`).

## Notes

- `TAUTULLI_DOCKER=True` tells Tautulli it is containerised (no in-app updater); bump the image instead.
- The compiled dependency set comes from upstream's `tautulli-baseimage` requirements file at build time, installed as wheels only (no toolchain in the runtime image).
