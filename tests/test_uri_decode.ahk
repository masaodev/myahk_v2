#Requires AutoHotkey v2.0
#Include ..\src\utils\uri_decode.ahk

; テスト結果を保存するファイル
testResultFile := "uri_decode_test_results.txt"

; テストケース（エンコードされた文字列）
testCases := [
    ; 基本的なパーセントエンコード
    "Hello%20World",
    "file%3A%2F%2F%2FC%3A%2Fpath%2Fto%2Ffile.txt",
    
    ; 日本語のUTF-8エンコード
    "%E6%97%A5%E6%9C%AC%E8%AA%9E",  ; "日本語"
    "%E3%83%95%E3%82%A1%E3%82%A4%E3%83%AB.txt",  ; "ファイル.txt"
    
    ; 特殊文字
    "%21%40%23%24%25%5E%26%2A%28%29",  ; "!@#$%^&*()"
    "%5B%5D%7B%7D%3C%3E",  ; "[]{}[]<>"
    
    ; スペースとプラス
    "hello%2Bworld",  ; "hello+world"
    "test%20with%20spaces",  ; "test with spaces"
    
    ; 複合的なテスト
    "C%3A%2Fpath%2Fto%2F%E6%97%A5%E6%9C%AC%E8%AA%9E%E3%83%95%E3%82%A1%E3%82%A4%E3%83%AB.txt",
    
    ; エラーケース
    "invalid%XX",  ; 無効な16進数
    "incomplete%2",  ; 不完全なエンコード
    "normal_text"  ; エンコードなし
]

; ファイルURLテストケース
fileUrlTestCases := [
    "file:///C:/path/to/file.txt",
    "file:///C:/path/to/file%20with%20spaces.txt",
    "file:///C:/path/to/%E6%97%A5%E6%9C%AC%E8%AA%9E%E3%83%95%E3%82%A1%E3%82%A4%E3%83%AB.txt"
]

; テスト実行
if FileExist(testResultFile)
    FileDelete(testResultFile)  ; 既存のファイルを削除

FileAppend("=== URIデコード関数のテスト ===`n`n", testResultFile)

; DecodeURIComponent関数のテスト
FileAppend("--- DecodeURIComponent関数のテスト ---`n", testResultFile)
for testCase in testCases {
    result := DecodeURIComponent(testCase)
    FileAppend("入力: " . testCase . "`n結果: " . result . "`n`n", testResultFile)
}

; DecodeUTF8URIComponent関数のテスト
FileAppend("`n--- DecodeUTF8URIComponent関数のテスト ---`n", testResultFile)
for testCase in testCases {
    result := DecodeUTF8URIComponent(testCase)
    FileAppend("入力: " . testCase . "`n結果: " . result . "`n`n", testResultFile)
}

; 空の入力のテスト
FileAppend("`n--- 空の入力のテスト ---`n", testResultFile)
result := DecodeURIComponent("")
FileAppend("DecodeURIComponent(''): " . result . "`n", testResultFile)

result := DecodeUTF8URIComponent("")
FileAppend("DecodeUTF8URIComponent(''): " . result . "`n", testResultFile)

FileAppend("`nテスト完了！結果は " . testResultFile . " に保存されました。`n", testResultFile) 