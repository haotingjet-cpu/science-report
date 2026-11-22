set -e

latexmk -c
latexmk -lualatex -shell-escape -interaction=nonstopmode report.tex

latexmk -c