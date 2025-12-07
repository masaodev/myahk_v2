; ===========================================
; メニュー設定とハンドラー関数
; ===========================================

#Include ../config/constants.ahk
#Include ../utils/common_func.ahk
#Include ../utils/uri_decode.ahk

; グローバル変数
hash := Map()
hashAll := Map()
hashMainMenu := Map()
hashMainMenuHotkey := Map()

; メインメニューを作成
createMainMenu() {
    myMenu := Menu()

    ; サブメニューの作成（固定）
    toolsMenu := createToolsMenu()
    toolsMenuAll := createToolsAllMenu()
    myFuncMenu := createFuncMenu()

    ; サブメニュー項目追加（固定）
    myMenu.add("t:ツール", toolsMenu)
    myMenu.add("a:ツール（全て）", toolsMenuAll)
    myMenu.add("s:Funcメニュー", myFuncMenu)

    ; アクション項目を設定ファイルから読み込み
    if FileExist(Constants.MAIN_MENU_CONFIG) {
        ; UTF-8として明示的に読み込む
        fileContent := FileRead(Constants.MAIN_MENU_CONFIG, "UTF-8")
        Loop Parse, fileContent, "`n", "`r"
        {
            line := Trim(A_LoopField)

            ; 空行またはコメント行をスキップ
            if (line == "" || SubStr(line, 1, 1) == ";") {
                continue
            }

            ; カンマで分割
            parts := StrSplit(line, ",")
            if (parts.Length >= 2) {
                displayName := Trim(parts[1])
                actionType := Trim(parts[2])
                hotkey := (parts.Length >= 3) ? Trim(parts[3]) : ""

                ; メニュー項目を追加
                myMenu.add(displayName, mainMenuActionHandler)

                ; アクションタイプとホットキーを保存
                hashMainMenu[displayName] := actionType
                if (hotkey != "") {
                    hashMainMenuHotkey[displayName] := hotkey
                }
            }
        }
    }

    return myMenu
}

; ツールメニューを作成
createToolsMenu() {
    toolsMenu := Menu()
    toolsMenu.Add("t:ツールフォルダを開く", otherTopMenuHandler)

    ; 設定ファイルから読み込み
    if FileExist(Constants.TOOLS_MENU_CONFIG) {
        ; UTF-8として明示的に読み込む
        fileContent := FileRead(Constants.TOOLS_MENU_CONFIG, "UTF-8")
        Loop Parse, fileContent, "`n", "`r"
        {
            line := Trim(A_LoopField)

            ; 空行またはコメント行をスキップ
            if (line == "" || SubStr(line, 1, 1) == ";") {
                continue
            }

            ; カンマで分割
            parts := StrSplit(line, ",")
            if (parts.Length >= 2) {
                displayName := Trim(parts[1])
                lnkName := Trim(parts[2])

                addMenu(toolsMenu, menuHandler, hash, displayName, lnkName)
            }
        }
    }

    return toolsMenu
}

; 全ツールメニューを作成
createToolsAllMenu() {
    toolsMenuAll := Menu()
    toolsMenuAll.Add("t:ツールフォルダを開く", otherTopMenuHandler)
    Loop Files, Constants.TOOL_FOLDER . "\*.lnk" {
        addMenu(toolsMenuAll, menuHandlerAll, hashAll, A_LoopFileName, A_LoopFileName)
    }
    return toolsMenuAll
}

; Funcメニューを作成
createFuncMenu() {
    menutmp := Menu()
    menutmp.add("t: 空白除去", handlerDeleteEmpty)
    menutmp.add("c: ゴミ箱を空にする", handlerFileRecycleEmpty)
    menutmp.add("b: ファイルバックアップ", handlerFileBackup)
    menutmp.add("m: メール用ファイルパス整形", handlerFormatForMail)
    menutmp.add("r: 行頭に(> )", handlerAddQuote)
    menutmp.add("q: SQL IN句生成", handlerCreateSqlInsentence)
    menutmp.add("p: パス変換（Git Bash⇔Windows）", handlerConvertPath)
    menutmp.add("w: パス変換（WSL⇔Windows）", handlerConvertPathWSL)
    menutmp.add("o: obsidianリンク生成", handlerCreateObsidianUrl)
    menutmp.add("u: URIデコード", handlerDecodeURI)
    menutmp.add()
    menutmp.add("テキスト化したショートカットを復元", handlerRestoreShortcutText)
    menutmp.add("フォルダ内ショートカットをテキスト化", handlerCreateShortcutText)
    menutmp.add()
    menutmp.add("s: 無効なショートカット管理（フォルダ選択）", handlerManageSelectedFolderShortcuts)
    menutmp.add("i: 無効なショートカットを管理（ツールフォルダ）", handlerManageInvalidShortcuts)
    return menutmp
}

; メニュー項目追加ヘルパー関数
addMenu(menuObj, hand, hashObj, displayName, lnkName) {
    lnkPath := Constants.TOOL_FOLDER "\" lnkName
    if(FileExist(lnkPath)) {
        exePath := getLnkTarget(lnkPath)
        menuObj.Add(displayName, hand)

        ; ショートカットのターゲットEXEからアイコンを自動取得
        try {
            menuObj.SetIcon(displayName, exePath)
        } catch {
            ; アイコン設定に失敗した場合は無視
        }

        hashObj[displayName] := exePath
    }
}

; メニューハンドラー
menuHandler(ItemName, ItemPos, MyMenu) {
    exePath := hash[ItemName]
    Run exePath
}

menuHandlerAll(ItemName, ItemPos, MyMenu) {
    exePath := hashAll[ItemName]
    Run exePath
}

; メインメニューアクションハンドラー
mainMenuActionHandler(ItemName, ItemPos, MyMenu) {
    actionType := hashMainMenu[ItemName]

    ; tool: で始まる場合はツール起動
    if (SubStr(actionType, 1, 5) == "tool:") {
        lnkFile := SubStr(actionType, 6)
        Run(getLnkTarget(Constants.TOOL_FOLDER "\" lnkFile))
        return
    }

    ; その他のアクションタイプ
    switch actionType {
        case "temp_memo":
            openTempMemo()
        case "obsidian":
            openObsidian()
        case "obsidian_switcher":
            openObsidianSwitcher()
        case "obsidian_memos":
            openObsidianMemosThino()
        case "open_clipboard":
            openAny(A_Clipboard)
        case "paste_plain":
            pasteText(Constants.WORK_DIR)
        case "open_work_dir":
            openWordDir(Constants.WORK_DIR)
        case "quickdash":
            ; QuickDashLauncher の特殊処理
            KeyWait("vk1D")
            Send("^!w")
    }
}

; ツールサブメニュー用ハンドラー（"t:ツールフォルダを開く" のみ）
otherTopMenuHandler(ItemName, ItemPos, MyMenu) {
    switch ItemName {
        case "t:ツールフォルダを開く":
            Run Constants.TOOL_FOLDER
    }
}

; メインメニューのホットキーを登録
registerMainMenuHotkeys() {
    ; 利用可能なNumpadキーのリスト
    numpadKeys := [
        "Numpad0", "Numpad1", "Numpad2", "Numpad3", "Numpad4",
        "Numpad5", "Numpad6", "Numpad7", "Numpad8", "Numpad9",
        "NumpadDot", "NumpadDiv", "NumpadMult", "NumpadAdd", "NumpadSub", "NumpadEnter"
    ]

    ; Numpadキーのインデックス
    numpadIndex := 1

    ; 各ホットキーに対してNumpadリレーを設定
    for displayName, key in hashMainMenuHotkey {
        if (numpadIndex > numpadKeys.Length) {
            ; Numpadキーが足りない場合は警告してスキップ
            MsgBox("警告: ホットキーの数がNumpadキーの数を超えています。`n" displayName " のホットキー登録をスキップします。")
            continue
        }

        actionType := hashMainMenu[displayName]
        numpadKey := numpadKeys[numpadIndex]

        ; vk1D & key -> Ctrl+Alt+NumpadX を送信
        Hotkey("vk1D & " key, ((nk) => ((*) => Send("^!{" nk "}")))(numpadKey))

        ; Ctrl+Alt+NumpadX -> アクション実行
        Hotkey("^!" numpadKey, ((at) => ((*) => executeMainMenuAction(at)))(actionType))

        numpadIndex++
    }
}

; アクションタイプに応じた処理を実行
executeMainMenuAction(actionType) {
    ; tool: で始まる場合はツール起動
    if (SubStr(actionType, 1, 5) == "tool:") {
        lnkFile := SubStr(actionType, 6)
        Run(getLnkTarget(Constants.TOOL_FOLDER "\" lnkFile))
        return
    }

    ; その他のアクションタイプ
    switch actionType {
        case "temp_memo":
            openTempMemo()
        case "obsidian":
            openObsidian()
        case "obsidian_switcher":
            openObsidianSwitcher()
        case "obsidian_memos":
            openObsidianMemosThino()
        case "open_clipboard":
            openAny(A_Clipboard)
        case "paste_plain":
            pasteText(Constants.WORK_DIR)
        case "open_work_dir":
            openWordDir(Constants.WORK_DIR)
        case "quickdash":
            ; QuickDashLauncher の特殊処理
            KeyWait("vk1D")
            Send("^!w")
    }
}
