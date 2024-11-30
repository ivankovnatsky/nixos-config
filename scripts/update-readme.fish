#!/usr/bin/env fish

cat README.md.template >README.md

tail -n +2 docs/nix-darwin.md >>README.md
