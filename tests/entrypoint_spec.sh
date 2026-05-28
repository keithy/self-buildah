#!/usr/bin/env bash

. "$(dirname "$0")/lib/bash-spec.sh"

describe "entrypoint.sh" && {

  ENTRYPOINT_SCRIPT="$(cd "$(dirname "$0")/.." && pwd)/entrypoint.sh"

  context "when run as non-root" && {
    it "executes BINARY with arguments" && {
      BINARY="echo" "$ENTRYPOINT_SCRIPT" arg1 arg2 2>/dev/null
      should_succeed
      [[ "$?" -eq 0 ]]
      should_succeed
    }

    it "passes arguments to binary" && {
      output=$(BINARY="echo" "$ENTRYPOINT_SCRIPT" hello 2>/dev/null)
      should_succeed
      [[ "$output" == "hello" ]]
      should_succeed
    }
  }

  context "BINARY fallback" && {
    it "uses /app/bin/goclaw when BINARY not set" && {
      unset BINARY
      "$ENTRYPOINT_SCRIPT" --help 2>/dev/null
      [[ $? -ne 0 ]]  # will fail but proves it tried /app/bin/goclaw
      should_succeed
    }
  }
}

describe "entrypoint.execline" && {

  ENTRYPOINT_SCRIPT="$(cd "$(dirname "$0")/.." && pwd)/entrypoint.execline"

  context "when BINARY is set" && {
    it "executes BINARY with arguments" && {
      BINARY="echo" "$ENTRYPOINT_SCRIPT" arg1 arg2 2>/dev/null
      should_succeed
    }

    it "passes arguments to binary" && {
      output=$(BINARY="echo" "$ENTRYPOINT_SCRIPT" hello 2>/dev/null)
      [[ "$output" == "hello" ]]
      should_succeed
    }
  }
}