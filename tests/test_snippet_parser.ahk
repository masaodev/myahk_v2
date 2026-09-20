#Requires AutoHotkey v2.0
; snippet_handler.ahk の parseSnippetText / expandSnippetBody のテスト
; 実行: autohotkey.exe tests\test_snippet_parser.ahk → snippet_parser_test_results.txt に結果

; Constants に依存する部分は使わないが #Include の解決のためダミーを用意
class Constants {
    static SNIPPETS_CONFIG := ""
}
#Include ..\src\handlers\snippet_handler.ahk

resultFile := "snippet_parser_test_results.txt"
try FileDelete(resultFile)
passed := 0
failed := 0

check(name, actual, expected) {
    global passed, failed, resultFile
    ok := (actual == expected)
    ok ? passed++ : failed++
    FileAppend((ok ? "PASS " : "FAIL ") name (ok ? "" : "`n  expected: [" expected "]`n  actual:   [" actual "]") "`n", resultFile, "UTF-8")
}

sample := "
(RTrim0
; 先頭コメント
[;ymd]
{date:yyyy/MM/dd}

[m1]
①

[;git] git switch -c 新規ブランチ作成
git pull ; git switch -c fix/{date:yyyyMMdd}-$|$ origin/main
; 本文の途中のコメント行は無視される

[;git] git branch -d ローカルブランチ削除
git branch -dTRAILING_SPACE

[;md] テーブル
|     |     |
| --- | --- |
|     |     |

[;esc]
\;セミコロン始まり
\[角括弧始まり

[;empty]


[;tail]
最後の行
)"

sample := StrReplace(sample, "TRAILING_SPACE", " ")  ; エディタに行末空白を落とされないための目印
items := parseSnippetText(sample)

check("トリガー数", items.Count, 7)
check("単一候補の本文", items[";ymd"][1].body, "{date:yyyy/MM/dd}")
check("ラベルなしは空", items[";ymd"][1].label, "")
check("丸数字", items["m1"][1].body, "①")
check("同一トリガーは 2 候補", items[";git"].Length, 2)
check("ラベル", items[";git"][1].label, "git switch -c 新規ブランチ作成")
check("本文中のコメント行は除く", items[";git"][1].body, "git pull " Chr(59) " git switch -c fix/{date:yyyyMMdd}-$|$ origin/main")
check("行末の空白は残す", items[";git"][2].body, "git branch -d ")
check("複数行は CRLF 連結", items[";md"][1].body, "|     |     |`r`n| --- | --- |`r`n|     |     |")
check("エスケープ", items[";esc"][1].body, ";セミコロン始まり`r`n[角括弧始まり")
check("空の本文", items[";empty"][1].body, "")
check("末尾ブロック", items[";tail"][1].body, "最後の行")

; 展開
today := FormatTime(, "yyyy/MM/dd")
check("date 既定書式", expandSnippetBody("{date}", ""), today)
check("date 書式指定", expandSnippetBody("a{date:yyyyMMdd}b", ""), "a" FormatTime(, "yyyyMMdd") "b")
check("date 複数", expandSnippetBody("{date:yyyy}-{date:MM}", ""), FormatTime(, "yyyy") "-" FormatTime(, "MM"))
check("clipboard", expandSnippetBody("<{clipboard}>", "X"), "<X>")

; CRLF 入力も同じ結果になる
itemsCrlf := parseSnippetText(StrReplace(sample, "`n", "`r`n"))
check("CRLF 入力でも同じ", itemsCrlf[";md"][1].body, items[";md"][1].body)

FileAppend("`n" passed " passed, " failed " failed`n", resultFile, "UTF-8")
ExitApp(failed ? 1 : 0)
