# 沐臻修改

這個資料夾放沐臻（與 Claude）對說明書的修改提案，**不會動到 repo 裡原本的任何檔案**。要不要採用、怎麼併入，由浩庭決定。

- `修改清單_YYYY-MM-DD.md`：這一輪改了什麼、為什麼。
- `沐臻修改.patch`：對照 repo 某個 commit 的差異檔（基準寫在修改清單裡），可用 `git apply 沐臻修改/沐臻修改.patch` 一次套用。
- 其餘檔案：照 repo 原路徑放的完整修改版（例如 `沐臻修改/pages/theory.tex` 對應 `pages/theory.tex`），也可以直接拿來覆蓋。

提醒：`pack.sh` 打包時會把這個資料夾一起打進 zip；不想打包的話，可在 `.packignore` 加一行 `沐臻修改`。
