; ===========================================
; ショートカットUI管理ハンドラー
; ===========================================

#Include ../config/constants.ahk

; メッセージボックスで無効なショートカットを表示
showInvalidShortcuts(invalidShortcuts) {
    content := formatInvalidShortcuts(invalidShortcuts)
    
    if (invalidShortcuts.Length == 0) {
        MsgBox(content, "チェック完了", "Icon!")
    } else {
        ; 長いメッセージの場合はテキストファイルとして保存することを提案
        if (StrLen(content) > 1000) {
            result := MsgBox(content . "`n`n詳細をテキストファイルに保存しますか？", 
                           "無効なショートカット検出", "YesNo Icon!")
            if (result == "Yes") {
                saveResult := saveInvalidShortcutsReport(invalidShortcuts)
                if (saveResult.success) {
                    MsgBox("ファイルを保存しました:`n" . saveResult.path, "保存完了", "Icon!")
                } else {
                    MsgBox("ファイルの保存に失敗しました: " . saveResult.error, "エラー", "IconX")
                }
            }
        } else {
            MsgBox(content, "無効なショートカット検出", "Icon!")
        }
    }
}

; ツールフォルダの無効なショートカットをチェックして表示
checkToolFolderShortcuts() {
    if (!DirExist(Constants.TOOL_FOLDER)) {
        MsgBox("ツールフォルダが存在しません: " . Constants.TOOL_FOLDER, "エラー", "IconX")
        return
    }
    
    invalidShortcuts := getInvalidShortcuts(Constants.TOOL_FOLDER)
    showInvalidShortcuts(invalidShortcuts)
}

; 無効なショートカット管理の共通処理
handleInvalidShortcutsManagement(targetFolder, guiTitle) {
    invalidShortcuts := getInvalidShortcuts(targetFolder)
    
    if (invalidShortcuts.Length == 0) {
        MsgBox("無効なショートカットは見つかりませんでした。", "チェック完了", "Icon!")
        return
    }
    
    ; アクション選択ダイアログ
    content := "対象フォルダ: " . targetFolder . "`n`n"
    content .= formatInvalidShortcuts(invalidShortcuts)
    content .= "`n実行するアクションを選択してください:"
    
    actionGui := Gui("+Resize", guiTitle)
    actionGui.SetFont("s10")
    
    ; 結果表示エリア
    actionGui.Add("Edit", "ReadOnly VScroll w600 h300", content)
    
    ; ボタン
    actionGui.Add("Button", "w120 h30", "詳細をファイル保存").OnEvent("Click", (*) => SaveDetails())
    actionGui.Add("Button", "x+10 w120 h30", "削除").OnEvent("Click", (*) => DeleteShortcuts())
    actionGui.Add("Button", "x+10 w120 h30", "閉じる").OnEvent("Click", (*) => actionGui.Destroy())
    
    actionGui.Show()
    
    SaveDetails() {
        saveResult := saveInvalidShortcutsReport(invalidShortcuts)
        if (saveResult.success) {
            MsgBox("ファイルを保存しました:`n" . saveResult.path, "保存完了", "Icon!")
        } else {
            MsgBox("ファイルの保存に失敗しました: " . saveResult.error, "エラー", "IconX")
        }
    }
    
    DeleteShortcuts() {
        ; 確認ダイアログ
        confirmContent := "以下の無効なショートカットを削除しますか？`n`n"
        confirmContent .= "フォルダ: " . targetFolder . "`n`n"
        for index, shortcut in invalidShortcuts {
            confirmContent .= index . ". " . shortcut.name . "`n"
        }
        
        result := MsgBox(confirmContent, "削除確認", 4+32)  ; YesNo + IconQuestion
        if (result == "Yes") {
            deleteResult := deleteInvalidShortcuts(invalidShortcuts)
            
            if (deleteResult.success) {
                message := deleteResult.deletedCount . "件のショートカットを削除しました。"
                if (deleteResult.failedCount > 0) {
                    message .= "`n" . deleteResult.failedCount . "件の削除に失敗しました。"
                }
                MsgBox(message, "削除完了", "Icon!")
            }
            actionGui.Destroy()
        }
    }
}

; 定期的なショートカットチェック（起動時チェック）
performStartupShortcutCheck() {
    if (!DirExist(Constants.TOOL_FOLDER)) {
        return
    }
    
    invalidShortcuts := getInvalidShortcuts(Constants.TOOL_FOLDER)
    
    if (invalidShortcuts.Length > 0) {
        content := "起動時チェック: " . invalidShortcuts.Length . "件の無効なショートカットが見つかりました。`n`n"
        content .= "詳細を確認しますか？"
        
        result := MsgBox(content, "起動時ショートカットチェック", "YesNo Icon!")
        if (result == "Yes") {
            handleInvalidShortcutsManagement(Constants.TOOL_FOLDER, "無効なショートカット管理")
        }
    }
} 