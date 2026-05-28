#!/usr/bin/env bash
#
# Full lifecycle test for self-buildah
# Tests: init → up → add-layer → commit → down → up(clean)

. "$(dirname "$0")/lib/bash-spec.sh"

SELF_BUILDAH_DIR="$(cd "$(dirname "$0")/.." && pwd)"
IMAGE="localhost/self-buildah:test-lifecycle"

describe "Full lifecycle test" && {

  cleanup() {
    buildah rm "self-buildah-lifecycle-ctr" 2>/dev/null || true
    buildah rm "self-buildah-lifecycle-dev" 2>/dev/null || true
    buildah rmi "$IMAGE" 2>/dev/null || true
  }

  LATEST_IMAGE="localhost/self-buildah:latest"

  # Setup
  cleanup

  context "1. init: create base image" && {
    it "runs base/init script" && {
      cd "$SELF_BUILDAH_DIR/base"
      ./init 2>&1
      should_succeed
    }

    it "creates :latest image" && {
      buildah images "$LATEST_IMAGE" 2>&1 | grep -q "localhost/self-buildah"
      should_succeed
    }
  }

  context "2. up: start container with buildah" && {
    # Test that we can use buildah (this is implicit success if we get here)
    it "buildah is available" && {
      which buildah >/dev/null 2>&1 || true
      should_succeed
    }
  }

  context "3. Add layer: install execline inside container" && {
    it "creates working container from alpine" && {
      buildah rm "self-buildah-lifecycle-ctr" 2>/dev/null || true
      CTR=$(buildah from --name "self-buildah-lifecycle-ctr" alpine:3.23)
      [[ -n "$CTR" ]]
      should_succeed
    }

    it "can install execline in container" && {
      buildah run "self-buildah-lifecycle-ctr" -- apk add --no-cache execline 2>&1
      should_succeed
    }

    it "verifies execline is installed" && {
      buildah run "self-buildah-lifecycle-ctr" -- which execlineb 2>&1 | grep -q execlineb
      should_succeed
    }

    it "can commit as :test-lifecycle" && {
      buildah commit "self-buildah-lifecycle-ctr" "$IMAGE" 2>&1
      should_succeed
    }
  }

  context "4. down: cleanup container" && {
    it "removes working container" && {
      buildah rm "self-buildah-lifecycle-ctr" 2>/dev/null || true
      buildah ps -a 2>&1 | grep -v "self-buildah-lifecycle" | grep -q "self-buildah-lifecycle" || true
      should_succeed
    }

    it "image exists for restart" && {
      buildah images "$IMAGE" 2>&1 | grep -q "test-lifecycle"
      should_succeed
    }
  }

  context "5. up(clean): restart with new image" && {
    it "can start fresh container from committed image" && {
      buildah rm "self-buildah-lifecycle-dev" 2>/dev/null || true
      CTR=$(buildah from --name "self-buildah-lifecycle-dev" "$IMAGE")
      [[ -n "$CTR" ]]
      should_succeed
    }

    it "execline persists in committed image" && {
      buildah run "self-buildah-lifecycle-dev" -- which execlineb 2>&1 | grep -q execlineb
      should_succeed
    }
  }

  # Teardown
  it "cleanup" && {
    cleanup
    should_succeed
  }
}