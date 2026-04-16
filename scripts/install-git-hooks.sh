#!/bin/sh

set -eu

git config core.hooksPath .githooks
chmod +x .githooks/commit-msg
echo "Git hooks configured to use .githooks/"
