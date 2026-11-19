set -e

rm -f report.out report.aux *.gz *.log

lualatex report.tex
lualatex report.tex

rm -f report.out report.aux *.gz *.log

