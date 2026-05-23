# self-buildah — Minimal Self-Building Container

## What This Project Is

A minimal Alpine-based container with **buildah installed** — it can build its own layers at runtime. No Dockerfile, no CI/CD pipeline. The container evolves itself by committing new image layers.

This is a lightweight sibling of the full setup at `../goclaw/options/buildah/`. Both follow the same self-building pattern but this one is stripped to the minimum.

## Project Type

Container scaffolding / buildah automation. **No application source code lives here.** The binary is bind-mounted from the host to `/usr/local/bin`.

## Actual Files

```
self-buildah/
├── base/
│   ├── init              # build :build + :latest images
│   ├── up               # launch the container (fuse + security opts)
│   ├── prune-buildah    # uninstall buildah, commit clean :build
│   └── stats            # show buildah images and containers
├── sbin/                # self-building scripts (on PATH as /usr/local/sbin)
├── bin/                 # application binary (on PATH as /usr/local/bin)
├── compose.yml           # podman compose reference (for flags)
├── entrypoint.sh         # shell entrypoint (root → nobody)
├── entrypoint.execline   # execlineb entrypoint
└── README.md
```

The `sbin/` scripts are sourced from `../goclaw/options/buildah/`. The `bin/` directory holds the application binary.

## Launching

compose.yml cannot express all requirements for running buildah inside a container (e.g. `--device /dev/fuse`). Use `base/up` instead:

```bash
./base/up                      # interactive
./base/up /bin/sh              # shell for debugging
```

First time: run `./base/init` to build the image.

compose.yml is useful for `podman compose up -d` (daemon mode) once you know the right flags.

## Key Architecture Decisions

### No Dockerfile
Builds use `buildah from alpine:3.23` then `buildah run` to layer packages. Each `ctr-*` target chains: `buildah run → buildah commit`. This is the self-building mechanism.

Buildah running rootless uses `$HOME/.local/share/containers` inside the container — that persists on restart naturally, so no extra volumes are needed for buildah storage.

### Binary Bind-Mount
Binary bind-mount maps `${BIN_DIR:-../bin}` to `/usr/local/bin`. Scripts mount `${SBIN_DIR:-../sbin}` to `/usr/local/sbin`. Both are on Alpine's default PATH.

No entrypoint needed — container runs as non-root user. Binary at `/usr/local/bin`, scripts at `/usr/local/sbin`.

### BUILDAH_ISOLATION=chroot
Set in compose.yml environment. Required for buildah to work inside a container (rootless buildah).

### No Shell in Base
The base image has **no shell installed**. The entrypoint uses `#!/bin/sh` (ash from busybox/Alpine) for its 3-line script only. Optional shells (execline, bash) are added via `make add-execline` / `make add-bash`.

## Reference Implementation

Canonical self-building container with full scripts: `../goclaw/options/buildah/`

Key files:
- `Makefile` — all `ctr-*` buildah targets
- `SELF_BUILDING.md` — design rationale

## Scripts

Scripts live in `sbin/` and should be executable. They use `#!/bin/sh` (ash from busybox/Alpine) — no bash assumed in base.

## Planned Commands

```bash
./base/init             # Build :build (with buildah) + :latest (clean) images
./base/up               # Launch :build image (with buildah) — interactive
./base/prune-buildah    # Uninstall buildah from running container, commit as clean :build
./base/stats            # Show buildah images and containers

# Workflow: init → up (layer) → prune-buildah → up (clean) → ...
```
