#!/bin/bash
set -euo pipefail

## Clean package manager cache on ostree stuff
dnf5 clean all
ostree container commit

# Clean temporary files
rm -rf /tmp/*
