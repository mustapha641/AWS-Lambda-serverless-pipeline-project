# Pillow Lambda layer

Run `./build.sh` (requires Docker) before the first `terraform apply`.
It compiles Pillow inside the official `public.ecr.aws/sam/build-python3.12`
image so the binary wheel matches the Amazon Linux runtime Lambda actually
uses, then zips it into `pillow-layer.zip`.

Re-run it whenever you bump the Pillow version in `requirements.txt`.

This file is intentionally not committed to git (see `.gitignore`) — every
environment builds its own to avoid shipping a stale binary.
