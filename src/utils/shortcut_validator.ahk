; 無効なショートカットを検出・管理するためのユーティリティ関数

; 指定されたフォルダ内の全ての.lnkファイルをチェックし、無効なショートカットの一覧を返す
getInvalidShortcuts(folderPath) {
    invalidShortcuts := Array()
    
    ; フォルダが存在しない場合は空配列を返す
    if (!DirExist(folderPath)) {
        return invalidShortcuts
    }
    
    ; フォルダ内の全ての.lnkファイルをチェック
    Loop Files, folderPath . "\*.lnk" {
        shortcutPath := A_LoopFileFullPath
        shortcutName := A_LoopFileName
        
        ; ショートカットのターゲットパスを取得
        try {
            targetPath := getLnkTarget(shortcutPath)
            
            ; ターゲットパスが空の場合は無効
            if (targetPath == "") {
                invalidShortcuts.Push({
                    name: shortcutName,
                    path: shortcutPath,
                    reason: "ターゲットパスが空です"
                })
                continue
            }
            
            ; ターゲットファイル/フォルダが存在しない場合は無効
            if (!FileExist(targetPath)) {
                invalidShortcuts.Push({
                    name: shortcutName,
                    path: shortcutPath,
                    target: targetPath,
                    reason: "ターゲットが存在しません"
                })
            }
        } catch Error as e {
            ; ショートカットの読み取りエラー
            invalidShortcuts.Push({
                name: shortcutName,
                path: shortcutPath,
                reason: "ショートカットの読み取りエラー: " . e.message
            })
        }
    }
    
    return invalidShortcuts
}

; 無効なショートカットの詳細情報を文字列として整形
formatInvalidShortcuts(invalidShortcuts) {
    if (invalidShortcuts.Length == 0) {
        return "無効なショートカットは見つかりませんでした。"
    }
    
    result := "無効なショートカット一覧 (" . invalidShortcuts.Length . "件):`n`n"
    
    for index, shortcut in invalidShortcuts {
        result .= index . ". " . shortcut.name . "`n"
        result .= "   パス: " . shortcut.path . "`n"
        if (shortcut.HasOwnProp("target")) {
            result .= "   ターゲット: " . shortcut.target . "`n"
        }
        result .= "   理由: " . shortcut.reason . "`n`n"
    }
    
    return result
}

; 無効なショートカットをファイルに出力
saveInvalidShortcutsToFile(invalidShortcuts, outputPath) {
    content := formatInvalidShortcuts(invalidShortcuts)
    content .= "`n生成日時: " . FormatTime(, "yyyy/MM/dd HH:mm:ss")
    
    try {
        FileAppend(content, outputPath)
        return {success: true, path: outputPath}
    } catch Error as e {
        return {success: false, error: e.message}
    }
}

; 無効なショートカットを削除する
deleteInvalidShortcuts(invalidShortcuts) {
    if (invalidShortcuts.Length == 0) {
        return {success: true, deletedCount: 0, failedCount: 0, message: "削除する無効なショートカットがありません。"}
    }
    
    deletedCount := 0
    failedCount := 0
    failedFiles := Array()
    
    for index, shortcut in invalidShortcuts {
        try {
            FileDelete(shortcut.path)
            deletedCount++
        } catch Error as e {
            failedCount++
            failedFiles.Push({name: shortcut.name, error: e.message})
        }
    }
    
    return {
        success: true,
        deletedCount: deletedCount,
        failedCount: failedCount,
        failedFiles: failedFiles
    }
}

; デスクトップに一意のファイル名でレポートを保存
saveInvalidShortcutsReport(invalidShortcuts) {
    timeString := FormatTime(,"yyyyMMdd_HHmmss")
    outputPath := A_Desktop . "\invalid_shortcuts_" . timeString . ".txt"
    return saveInvalidShortcutsToFile(invalidShortcuts, outputPath)
}
