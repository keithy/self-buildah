# Minimal Self-Building Container

A minimal Alpine-based container with **buildah installed** — it can build its own layers at runtime. No Dockerfile, no CI/CD pipeline. The container evolves itself.

## Quick Start

```bash
# 1. Build base images (run once)
./base/init
#   → :build  (with buildah — for self-layering)
#   → :latest (clean — no buildah)

# 2. Start the build image
./base/up              # starts :build image

# 3. When done layering: uninstall buildah, commit clean
./base/prune-buildah   # apk del buildah, commit → :build (clean)

# 4. Run the clean image
IMAGE=localhost/self-buildah:latest ./base/up
```

## Design

```
┌──────────────────────────────────────────────────────────┐
│  Container: alpine + buildah + fuse-overlayfs            │
│                                                          │
│  /usr/local/bin/    ← binary (bind-mounted from ../bin/)  │
│  /usr/local/sbin/   ← scripts (bind-mounted from ../sbin/) │
│                                                          │
│  Buildah uses $HOME/.local/share/containers inside      │
│  the container — persists across restarts.              │
│                                                          │
│  Base: ash (busybox), coreutils, grep/sed/gawk/tar     │
│  Optional layers: execline, bash, python, node, etc.   │
└──────────────────────────────────────────────────────────┘
```

Binary is **bind-mounted to `/usr/local/bin`**, scripts to `/usr/local/sbin`. Both on PATH.

## Structure

```
self-buildah/
├── base/
│   ├── init              # build :build + :latest images
│   ├── up               # launch the container (fuse + security opts)
│   ├── prune-buildah    # uninstall buildah, commit clean :build
│   └── stats            # show buildah images and containers
├── sbin/                # self-building scripts
├── bin/                 # application binary (bind-mounted)
├── compose.yml           # podman compose reference (for flags)
├── entrypoint.sh         # shell entrypoint (root → nobody)
├── entrypoint.execline   # execlineb entrypoint
└── README.md
```

## Layers

Base image has **no shell** (execline and bash are installable layers). Scripts use `#!/bin/sh` (ash from busybox) for compatibility.

| Layer | Package | Purpose |
|-------|---------|---------|
| base | busybox/ash, coreutils, GNU grep/sed/gawk | Minimal runtime (ash always present from Alpine) |

## Setup

Binary at `../bin/`, scripts at `../sbin/`. Then run `./base/up`.

## From Inside the Container

The running container can self-improve by running buildah commands and committing layers.

## Cleanup

```bash
podman rmi localhost/self-buildah:latest   # remove image
buildah rmi --all                          # clean buildah cache
```

## See Also

- [../goclaw/options/buildah/](../goclaw/options/buildah/) — full self-building container with Makefile and scripts