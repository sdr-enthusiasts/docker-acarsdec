#!/usr/bin/env bash

set -x

ls -la /opt/

# determine which binary to keep
if /opt/acars-bridge.amd64 --version > /dev/null 2>&1; then
    mv -v /opt/acars-bridge.amd64 /opt/acars-bridge
elif /opt/acars-bridge.arm64 --version > /dev/null 2>&1; then
    mv -v /opt/acars-bridge.arm64 /opt/acars-bridge
elif /opt/acars-bridge.armv7 --version > /dev/null 2>&1; then
    mv -v /opt/acars-bridge.armv7 /opt/acars-bridge
else
    >&2 echo "ERROR: Unsupported architecture"
    exit 1
fi
