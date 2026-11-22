#!/usr/bin/env bash
# pack.sh - 將資料夾打包成 zip，並依 <目標資料夾>/.packignore（.gitignore 語法）排除檔案
#
# 用法：
#   ./pack.sh [-t 資料夾] [-n 輸出檔名.zip] [-git]
#
# 範例：
#   ./pack.sh -t . -n target.zip
#   ./pack.sh -t ./src -n src.zip
#   ./pack.sh -t . -n target.zip -git   # 輸出 target.<短 commit hash>.zip
#
# 依賴：bash、zip、git（git 只用來解析 .gitignore 規則，不需要目標資料夾是 git repo）

set -euo pipefail

usage() {
    cat <<'EOF'
用法: pack.sh [-t 資料夾] [-n 輸出檔名] [-git]

  -t  要打包的資料夾（預設為 .）
  -n  輸出的 zip 檔名（預設為 <資料夾名稱>.zip，相對於執行指令時的目錄）
  -git  在檔名中加入目標資料夾目前的 commit 短 hash，
        例如 -n target.zip -git → target.<hash>.zip
  -h  顯示說明

若資料夾最上層存在 .packignore，會依 .gitignore 語法排除符合的檔案。
EOF
}

target="."
name=""
use_git=0

# getopts 不支援多字元旗標，先把 -git / --git 轉成單字元 -g
args=()
for a in "$@"; do
    case "$a" in
        -git|--git) args+=("-g") ;;
        *) args+=("$a") ;;
    esac
done
set -- "${args[@]+"${args[@]}"}"

while getopts ":t:n:gh" opt; do
    case "$opt" in
        g) use_git=1 ;;
        t) target="$OPTARG" ;;
        n) name="$OPTARG" ;;
        h) usage; exit 0 ;;
        :) echo "錯誤: -$OPTARG 需要參數" >&2; usage >&2; exit 1 ;;
        \?) echo "錯誤: 未知選項 -$OPTARG" >&2; usage >&2; exit 1 ;;
    esac
done

for cmd in zip git xargs; do
    command -v "$cmd" >/dev/null 2>&1 || { echo "錯誤: 找不到 $cmd" >&2; exit 1; }
done

[ -d "$target" ] || { echo "錯誤: 資料夾不存在: $target" >&2; exit 1; }
target="$(cd "$target" && pwd)"

if [ -z "$name" ]; then
    name="$(basename "$target").zip"
fi
case "$name" in *.zip) ;; *) name="$name.zip" ;; esac

# -git：檔名改為 <name>.<COMMIT_HASH>.zip
if [ "$use_git" -eq 1 ]; then
    if ! COMMIT_HASH="$(git -C "$target" rev-parse --short HEAD 2>/dev/null)"; then
        echo "錯誤: $target 不是 git repo，或尚無任何 commit，無法取得 commit hash" >&2
        exit 1
    fi
    name="${name%.zip}.${COMMIT_HASH}.zip"
fi

# 輸出檔以絕對路徑表示（相對於執行指令時的目錄）
case "$name" in
    /*) out="$name" ;;
    *)  out="$PWD/$name" ;;
esac

ignore_file="$target/.packignore"
if [ -f "$ignore_file" ]; then
    exclude_args=(--exclude-from="$ignore_file")
else
    exclude_args=()
fi

# 借用暫時的空 git 目錄，讓 git 以 .gitignore 規則比對 .packignore
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
git init -q "$tmp"

rm -f "$out"

# 若輸出檔位於打包資料夾內，將它排除，避免把自己打包進去
self_rel=""
case "$out" in
    "$target"/*) self_rel="${out#"$target"/}" ;;
esac

cd "$target"

list="$tmp/files.list"
git -c core.excludesFile=/dev/null \
    --git-dir="$tmp/.git" --work-tree="$target" \
    ls-files -z --others "${exclude_args[@]}" > "$list"

# 過濾掉輸出檔本身（以 NUL 分隔處理）
filtered="$tmp/files.filtered"
: > "$filtered"
count=0
while IFS= read -r -d '' f; do
    [ -n "$self_rel" ] && [ "$f" = "$self_rel" ] && continue
    printf '%s\0' "$f" >> "$filtered"
    count=$((count + 1))
done < "$list"

if [ "$count" -eq 0 ]; then
    echo "警告: 沒有任何檔案被打包（全部被排除或資料夾為空）" >&2
    exit 1
fi

# xargs 若分批呼叫 zip，zip 會把檔案追加到同一個壓縮檔
xargs -0 zip -q "$out" -- < "$filtered"

echo "已建立: $out（共 $count 個檔案）"