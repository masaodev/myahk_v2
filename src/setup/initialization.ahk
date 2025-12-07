; ===========================================
; 初期化処理
; ===========================================

#Include ../config/constants.ahk
#Include ../utils/common_func.ahk

; アプリケーション初期化
initializeApplication() {
    ; 必要なフォルダを作成
    createRequiredFolders()
    
    ; バックアップを実行
    performBackup()
    
    ; 空フォルダを削除
    removeEmptyFolders(Constants.WORK_DIR)
    
    ; 起動時の無効ショートカットチェック（オプション）
    performStartupShortcutCheck()
}

; 必要なフォルダを作成
createRequiredFolders() {
    createFolderWhenNotExists(Constants.TOOL_FOLDER)
    createFolderWhenNotExists(Constants.WORK_DIR)
    createFolderWhenNotExists(Constants.BACKUP_FOLDER)
    createFolderWhenNotExists(Constants.BACKUP_TOOLS_FOLDER)
}

; バックアップを実行
performBackup() {
    ; TOOL_FOLDERをBACKUP_TOOLS_FOLDERにコピー
    DirCopy(Constants.TOOL_FOLDER, Constants.BACKUP_TOOLS_FOLDER, 1)  ; 1は上書きを許可
} 