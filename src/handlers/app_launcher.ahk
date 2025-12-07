; ===========================================
; アプリケーション起動関連の関数
; ===========================================

#Include ../config/constants.ahk

; Obsidianスイッチャーを開く
openObsidianSwitcher() {
    ; まずはObsidianで全体目次を開く
    openObsidian()
    ; Obsidianのスイッチャーを開く
    Run(Constants.OBSIDIAN_SWITCHER_URI)
}

; Obsidianを開く
openObsidian() {
    ; Obsidianで全体目次を開く
    Run(Constants.OBSIDIAN_OPEN_URI)
}

; 一時メモを開く
openTempMemo() {
    Run(Constants.TEMP_MEMO_PATH)
}

; Obsidian Memos (Thino)を開く
openObsidianMemosThino() {
    Run(Constants.OBSIDIAN_MEMOS_THINO_URI)
} 