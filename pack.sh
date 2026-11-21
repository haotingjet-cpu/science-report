#!/bin/bash
set -e

COMMIT_HASH=$(git rev-parse --short HEAD)
latexmk -lualatex -shell-escape -interaction=nonstopmode report.tex
latexmk -c
mkdir -p Assets
zip -r "Assets/科展.$COMMIT_HASH.zip" ./* -x "Assets/*" "pack.sh" "*.bbl" "*.run.xml" "*.DS_Store"
