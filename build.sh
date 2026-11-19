set -e

for i in {1..5}
do
    rm -f report.out report.aux *.gz *.log
    # 產生 aux
    lualatex report.tex
    for i in {0..5}
    do
        lualatex report.tex
        sleep 2
    done
    rm -f report.out report.aux *.gz *.log
    sleep 2
done
