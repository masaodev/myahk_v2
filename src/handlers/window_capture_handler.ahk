; ===========================================
; ウィンドウキャプチャーモード + 仮想デスクトップ移動
; ===========================================

#Include ../utils/virtual_desktop.ahk

global _captureMode := false

;; Funcメニューから呼ばれるエントリーポイント
handlerWindowCapture(ItemName, ItemPos, MyMenu) {
    global _captureMode

    try {
        VirtualDesktop.Init()
    } catch Error as e {
        MsgBox("仮想デスクトップ機能の初期化に失敗しました。`n" e.Message "`n`nlib\VirtualDesktopAccessor.dll を配置してください。", "エラー", "IconX")
        return
    }

    _captureMode := true
    setCrossCursor()
    TrayTip("ウィンドウ操作モード", "移動したいウィンドウをクリックしてください。`nESCキーでキャンセルします。")
    SetTimer(captureModeTick, 50)
}

;; ポーリング処理（50ms間隔）
captureModeTick() {
    global _captureMode

    if (!_captureMode) {
        SetTimer(captureModeTick, 0)
        return
    }

    if (GetKeyState("Escape", "P")) {
        endCaptureMode()
        TrayTip("キャンセル", "ウィンドウ操作モードを終了しました。")
        return
    }

    if (GetKeyState("LButton", "P")) {
        MouseGetPos(, , &targetHwnd)
        if (targetHwnd) {
            endCaptureMode()
            KeyWait("LButton")
            Sleep(100)
            showWindowActionMenu(targetHwnd)
        }
    }
}

endCaptureMode() {
    global _captureMode
    _captureMode := false
    SetTimer(captureModeTick, 0)
    restoreCursor()
}

;; ウィンドウアクションメニューを表示
showWindowActionMenu(hwnd) {
    try {
        title := WinGetTitle("ahk_id " hwnd)
    } catch {
        title := "(取得失敗)"
    }
    if (title == "") {
        title := "(無題)"
    }
    if (StrLen(title) > 40) {
        title := SubStr(title, 1, 37) "..."
    }

    try {
        desktopNum := VirtualDesktop.GetWindowDesktopNumber(hwnd)
        desktopCount := VirtualDesktop.GetDesktopCount()
        isPinned := VirtualDesktop.IsPinnedWindow(hwnd)
        pinStatus := isPinned ? " [固定中]" : ""
        desktopInfo := "デスクトップ " (desktopNum + 1) " / " desktopCount . pinStatus
    } catch {
        desktopInfo := "デスクトップ情報取得失敗"
        isPinned := false
    }

    actionMenu := Menu()
    actionMenu.Add(title, (*) => 0)
    actionMenu.Disable(title)
    actionMenu.Add(desktopInfo, (*) => 0)
    actionMenu.Disable(desktopInfo)
    actionMenu.Add()

    if (isPinned) {
        actionMenu.Add("全デスクトップ固定を解除", (*) => unpinWindow(hwnd))
    } else {
        actionMenu.Add("全デスクトップに固定", (*) => pinWindow(hwnd))
    }

    actionMenu.Add()
    actionMenu.Add("次のデスクトップへ移動（追従なし）", (*) => moveWindowToDesktop(hwnd, 1, false))
    actionMenu.Add("前のデスクトップへ移動（追従なし）", (*) => moveWindowToDesktop(hwnd, -1, false))
    actionMenu.Add()
    actionMenu.Add("次のデスクトップへ移動", (*) => moveWindowToDesktop(hwnd, 1, true))
    actionMenu.Add("前のデスクトップへ移動", (*) => moveWindowToDesktop(hwnd, -1, true))
    actionMenu.Show()
}

;; ウィンドウを隣接デスクトップへ移動し結果を通知
moveWindowToDesktop(hwnd, direction, follow) {
    try {
        dest := VirtualDesktop.MoveWindowToAdjacentDesktop(hwnd, direction, follow)
        suffix := follow ? "" : "（追従なし）"
        TrayTip("移動完了", "デスクトップ " (dest + 1) " へ移動しました。" suffix)
    } catch Error as e {
        MsgBox("移動に失敗しました: " e.Message, "エラー", "IconX")
    }
}

;; ウィンドウを全デスクトップに固定
pinWindow(hwnd) {
    try {
        VirtualDesktop.PinWindow(hwnd)
        TrayTip("固定完了", "ウィンドウを全デスクトップに固定しました。")
    } catch Error as e {
        MsgBox("固定に失敗しました: " e.Message, "エラー", "IconX")
    }
}

;; ウィンドウの固定を解除
unpinWindow(hwnd) {
    try {
        VirtualDesktop.UnPinWindow(hwnd)
        TrayTip("固定解除", "ウィンドウの固定を解除しました。")
    } catch Error as e {
        MsgBox("固定解除に失敗しました: " e.Message, "エラー", "IconX")
    }
}

;; カーソルを十字カーソルに変更
setCrossCursor() {
    crossCursor := DllCall("LoadCursor", "Ptr", 0, "Ptr", 32515, "Ptr")
    for id in [32512, 32513, 32649] {
        copyCursor := DllCall("CopyIcon", "Ptr", crossCursor, "Ptr")
        DllCall("SetSystemCursor", "Ptr", copyCursor, "UInt", id)
    }
}

;; カーソルを元に戻す
restoreCursor() {
    DllCall("SystemParametersInfo", "UInt", 0x0057, "UInt", 0, "Ptr", 0, "UInt", 0)
}
