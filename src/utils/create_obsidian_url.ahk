#Requires AutoHotkey v2.0

CreateObsidianUrl(input := "") {
    ; 入力が空の場合、クリップボードからテキストを取得
    if (input = "") {
        input := A_Clipboard
    }

    ; 入力が空の場合、ファイルパスを取得
    if (input = "") {
        try {
            ; ファイルドロップリストから最初のファイルパスを取得
            input := FileSelect("", , "ファイルを選択")
        }
    }

    ; バックスラッシュをスラッシュに置換
    input := StrReplace(input, "\", "/")

    ; ファイル名を取得
    name := SubStr(input, InStr(input, "/", , -1) + 1)

    ; URIエンコード
    encoded := EncodeURIComponent(input)

    ; ":"と"/"を復元
    encoded := StrReplace(StrReplace(encoded, "%3A", ":"), "%2F", "/")

    ; マークダウン形式のテキストを生成
    result := Format("[{1}](file:///{2})", name, encoded)

    ; クリップボードに設定
    A_Clipboard := result
    
    ; 結果を返す
    return result
}

; URIエンコード関数
EncodeURIComponent(str) {
    ; 安全な文字セット（エンコードしない文字）
    static safeChars := "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_.!~*'()"
    encoded := ""
    
    ; 文字列をUTF-8バイト列に変換
    utf8 := StrPut(str, "UTF-8")
    bytes := Buffer(utf8, 0)
    StrPut(str, bytes, "UTF-8")
    
    ; バイト列を処理
    Loop utf8 {
        byte := NumGet(bytes, A_Index - 1, "UChar")
        char := Chr(byte)
        
        ; 安全な文字はそのまま、それ以外はパーセントエンコード
        if InStr(safeChars, char)
            encoded .= char
        else
            encoded .= "%" . Format("{:02X}", byte)
    }
    
    return encoded
} 