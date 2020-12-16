#!/bin/bash

set -e

filename=dps-widget-$(git describe --abbrev=0 --tags).pk3

rm -f $filename
zip -R $filename "*.md" "*.txt" "*.zs" "*.png"
gzdoom $filename "$@"
