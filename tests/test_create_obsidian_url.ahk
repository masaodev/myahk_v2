#Requires AutoHotkey v2.0
#Include ..\src\utils\create_obsidian_url.ahk

; テスト結果を保存するファイル
testResultFile := "test_results.txt"

; テストケース
testCases := [
    "C:\path\to\file.txt",
    "C:\path\to\file with spaces.txt",
    "C:\path\to\日本語ファイル.txt",
    "C:\path\to\file#with#special#chars.txt",
    "C:\path\to\file with (parentheses).txt",
    "C:\path\to\file with [brackets].txt",
    "C:\path\to\file with {braces}.txt",
    "C:\path\to\file with & and + chars.txt"
]

; テスト実行
if FileExist(testResultFile)
    FileDelete(testResultFile)  ; 既存のファイルを削除
for testCase in testCases {
    ; 関数を実行
    result := CreateObsidianUrl(testCase)
    
    ; 結果を表示
    FileAppend("テストケース: " . testCase . "`n結果: " . result . "`n`n", testResultFile)
}

; 空の入力のテスト
result := CreateObsidianUrl("")
FileAppend("空の入力のテスト`n結果: " . result . "`n`n", testResultFile) 