#!/usr/bin/env bash
# Builds a Lambda layer containing Pillow, compiled for Amazon Linux
# (the manylinux wheels installed on a Mac/Windows dev machine will NOT
# work directly in Lambda - Pillow ships C extensions).
#
# Usage: ./build.sh
# Produces: pillow-layer.zip in this directory, referenced by
#           infra/modules/lambda/main.tf

set -euo pipefail

WORKDIR=$(mktemp -d)
PYTHON_DIR="$WORKDIR/python"
mkdir -p "$PYTHON_DIR"

docker run --rm \
  -v "$WORKDIR":/var/task \
  public.ecr.aws/sam/build-python3.12 \
  pip install Pillow -t /var/task/python

cd "$WORKDIR"
zip -r pillow-layer.zip python > /dev/null
mv pillow-layer.zip "$(dirname "$0")/pillow-layer.zip"
rm -rf "$WORKDIR"

echo "Built $(dirname "$0")/pillow-layer.zip"
