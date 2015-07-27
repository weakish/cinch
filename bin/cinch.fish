#!/usr/bin/env fish

# Usage:
#
#     cinch DIRECTORY

find $argv[1] -print0 -type f |
xargs -0 -L1 xxh64sum |
tee -a /pool/.cinch/files.xxh64
