#Requires AutoHotkey v2.0

; URIデコード関数
DecodeURIComponent(str) {
    decoded := ""
    i := 1
    
    while (i <= StrLen(str)) {
        if (SubStr(str, i, 1) = "%") {
            ; パーセントエンコードされた文字をデコード
            if (i + 2 <= StrLen(str)) {
                hexStr := SubStr(str, i + 1, 2)
                try {
                    ; 16進数を10進数に変換
                    byteValue := Integer("0x" . hexStr)
                    ; バイト値を文字に変換
                    decoded .= Chr(byteValue)
                    i += 3
                } catch {
                    ; エラーの場合はそのまま追加
                    decoded .= SubStr(str, i, 1)
                    i++
                }
            } else {
                ; パーセント記号だけの場合はそのまま追加
                decoded .= SubStr(str, i, 1)
                i++
            }
        } else {
            ; 通常の文字はそのまま追加
            decoded .= SubStr(str, i, 1)
            i++
        }
    }
    
    return decoded
}

; UTF-8バイト列からの文字列デコード関数
DecodeUTF8URIComponent(str) {
    ; まず基本的なURIデコードを実行
    basicDecoded := DecodeURIComponent(str)
    
    ; UTF-8バイト列を文字列に変換
    try {
        ; バイト配列を作成
        byteArray := Buffer(StrLen(basicDecoded))
        Loop StrLen(basicDecoded) {
            NumPut("UChar", Ord(SubStr(basicDecoded, A_Index, 1)), byteArray, A_Index - 1)
        }
        
        ; UTF-8として文字列に変換
        result := StrGet(byteArray, "UTF-8")
        return result
    } catch {
        ; エラーの場合は基本デコード結果を返す
        return basicDecoded
    }
}
