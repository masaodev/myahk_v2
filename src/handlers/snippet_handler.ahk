; ===========================================
; スニペット（定型文）展開ハンドラー
; ===========================================
; %USERPROFILE%\.myahk_v2\snippets.txt を読み、トリガー文字列を打つと本文を貼り付ける。
; espanso / Lintalist の代替として「使う機能だけ」を持つ:
;   - 打つと即展開（終端文字不要・単語の途中でも発火・大文字小文字は区別）
;   - 同じトリガーが複数あればカーソル位置に候補メニューを出して選ぶ
;   - 本文中の {date:書式} を今日の日付に、{clipboard} をクリップボードに置き換える
;   - パラメータ: {input:名前} 1 行入力 / {input:名前=既定値} / {textarea:名前} 複数行 /
;     {choice:名前=a|b|c} 選択。1 つのスニペットにある分をまとめて 1 つのフォームで聞く。
;     同じ名前は 1 回だけ聞いて全箇所に入る
;   - $|$ で貼り付け後のカーソル位置を指定
;   - 複数行や長い本文はクリップボード経由で貼り付け（元のクリップボードは復元）
;   - 本文が {search} または {search:初期フィルタ} のトリガーは検索窓を開く（例: [;;] → {search}）。
;     候補メニューの末尾「🔍 絞り込み…」からも、そのトリガーの候補だけを検索窓で絞れる
; ファイル監視はしない。編集後は Func メニューの「スニペット再読込」で反映する。
;
; 設定ファイルの書式（config_samples/snippets.txt.sample も参照）:
;   [トリガー] ラベル      ← 見出し。ラベルは候補メニューの表示名（省略可）
;   本文行...              ← 次の見出しまでが本文（前後の空行は除く。行末の空白は残す）
;   ; で始まる行はコメント。本文の行頭を ; や [ にしたいときは \; \[ と書く

class SnippetStore {
    static items := Map()      ; トリガー -> [{label, body}, ...]
    static active := Map()     ; 登録済みホットストリング（トリガー -> true）
    static lastError := ""
}

; 設定ファイルを読み直してホットストリングを登録し直す
loadSnippets(notify := false) {
    ; 以前の登録を無効化（設定から消えたトリガーを残さない）
    for trigger in SnippetStore.active {
        try Hotstring(snippetHotstringName(trigger), , "Off")
    }
    SnippetStore.active := Map()
    SnippetStore.items := Map()
    SnippetStore.lastError := ""

    if !FileExist(Constants.SNIPPETS_CONFIG) {
        if notify
            MsgBox("スニペット設定が見つかりません:`n" Constants.SNIPPETS_CONFIG, "スニペット", "Icon!")
        return 0
    }

    try {
        SnippetStore.items := parseSnippetText(FileRead(Constants.SNIPPETS_CONFIG, "UTF-8"))
    } catch as e {
        SnippetStore.lastError := e.Message
        MsgBox("スニペット設定の読み込みに失敗しました:`n" e.Message, "スニペット", "Icon!")
        return 0
    }

    count := 0
    for trigger, list in SnippetStore.items {
        Hotstring(snippetHotstringName(trigger), snippetFire.Bind(trigger), "On")
        SnippetStore.active[trigger] := true
        count += list.Length
    }
    if notify
        TrayTip("スニペットを再読込しました（トリガー " SnippetStore.items.Count " 件・候補 " count " 件）", "myahk_v2")
    return count
}

; ホットストリング名。* 終端文字不要 / ? 単語の途中でも発火 / C 大文字小文字を区別
snippetHotstringName(trigger) {
    return ":*?C:" trigger
}

; 設定テキストを Map(トリガー -> [{label, body}]) に変換する（テストしやすいよう純粋関数）
parseSnippetText(text) {
    result := Map()
    current := ""          ; 現在のトリガー
    label := ""
    lines := []            ; 本文行の蓄積

    flush() {
        if (current = "")
            return
        ; 前後の空行だけ除く（行末の空白は本文の一部として残す）
        while (lines.Length && Trim(lines[1]) = "")
            lines.RemoveAt(1)
        while (lines.Length && Trim(lines[lines.Length]) = "")
            lines.Pop()
        body := ""
        for i, l in lines
            body .= (i > 1 ? "`r`n" : "") l
        if !result.Has(current)
            result[current] := []
        result[current].Push({label: label, body: body})
    }

    text := StrReplace(text, "`r`n", "`n")
    Loop Parse, text, "`n" {
        line := A_LoopField
        if RegExMatch(line, "^\[(.+?)\](.*)$", &m) {
            flush()
            current := m[1]
            label := Trim(m[2])
            lines := []
            continue
        }
        if (SubStr(line, 1, 1) = ";")
            continue
        if (SubStr(line, 1, 2) = "\;" || SubStr(line, 1, 2) = "\[")
            line := SubStr(line, 2)
        if (current != "")
            lines.Push(line)
    }
    flush()
    return result
}

; トリガーが打たれたとき: 候補が 1 つなら即貼り付け、複数ならメニューで選ぶ
snippetFire(trigger, *) {
    if !SnippetStore.items.Has(trigger)
        return
    list := SnippetStore.items[trigger]
    if (list.Length = 1) {
        snippetPaste(list[1])
        return
    }
    candidates := Menu()
    for item in list {
        ; ラベル<Tab>本文プレビュー（Tab 以降はメニューの右列に出る）
        preview := snippetPreview(item.body)
        name := item.label != "" ? item.label "`t" preview : preview
        candidates.Add(name, snippetPasteFromMenu.Bind(item))
    }
    candidates.Add()
    candidates.Add("🔍 絞り込み…`t" trigger " の候補を検索窓で絞る", (*) => showSnippetPicker(trigger))
    ; 選択中の項目の本文をツールチップで全文表示するため、メニュー項目 ID -> 本文 を控える
    SnippetMenuState.bodies := Map()
    SnippetMenuState.positions := Map()
    for i, item in list {
        id := DllCall("GetMenuItemID", "ptr", candidates.Handle, "int", i - 1, "int")
        SnippetMenuState.bodies[id] := item.body
        SnippetMenuState.positions[id] := i - 1
    }
    SnippetMenuState.hMenu := candidates.Handle
    OnMessage(0x011F, snippetOnMenuSelect)      ; WM_MENUSELECT
    showMenuAtCaret(candidates)                 ; メニューが閉じるまで戻らない
    OnMessage(0x011F, snippetOnMenuSelect, 0)
    ToolTip()
}

class SnippetMenuState {
    static bodies := Map()       ; メニュー項目 ID -> 本文
    static positions := Map()    ; メニュー項目 ID -> 位置（0 始まり）
    static hMenu := 0
}

; メニューで項目が選択（ハイライト）されたら、その項目の右に本文全文をツールチップで出す
snippetOnMenuSelect(wParam, lParam, msg, hwnd) {
    id := wParam & 0xFFFF
    flags := (wParam >> 16) & 0xFFFF
    if (lParam = 0 || (flags & 0x10) || !SnippetMenuState.bodies.Has(id)) {   ; 閉じた / サブメニュー / 対象外
        ToolTip()
        return
    }
    body := SnippetMenuState.bodies[id]
    ; 項目の画面上の位置を取り、メニューの右隣に出す
    pos := SnippetMenuState.positions[id]
    rect := Buffer(16, 0)
    CoordMode("ToolTip", "Screen")
    if DllCall("GetMenuItemRect", "ptr", 0, "ptr", SnippetMenuState.hMenu, "uint", pos, "ptr", rect)
        ToolTip(snippetTooltipText(body), NumGet(rect, 8, "int") + 8, NumGet(rect, 4, "int"))
    else
        ToolTip(snippetTooltipText(body))
}

; ツールチップ用に本文を整える（長すぎるものは切る）
snippetTooltipText(body) {
    rows := StrSplit(body, "`n", "`r")
    if (rows.Length > 40) {
        text := ""
        Loop 40
            text .= rows[A_Index] "`n"
        return text "…（残り " rows.Length - 40 " 行）"
    }
    return body
}

snippetPasteFromMenu(item, *) {
    snippetPaste(item)
}

; メニューに出す本文プレビュー: 1 行目（60 文字まで）。2 行目以降があれば「 ⏎…」を付ける
snippetPreview(body) {
    rows := StrSplit(body, "`n", "`r")
    first := rows.Length ? rows[1] : ""
    if (StrLen(first) > 60)
        first := SubStr(first, 1, 60) "…"
    return first (rows.Length > 1 ? " ⏎…" : "")
}

; カーソル位置（取れなければマウス位置）にメニューを出す
showMenuAtCaret(candidates) {
    CoordMode("Caret", "Screen")
    CoordMode("Menu", "Screen")
    if CaretGetPos(&x, &y)
        candidates.Show(x, y + 20)
    else
        candidates.Show()
}

; 本文を展開して貼り付ける
snippetPaste(item) {
    if RegExMatch(item.body, "^\{search(?::(.*))?\}$", &sm) {
        showSnippetPicker(sm[1])
        return
    }
    clipBefore := ClipboardAll()
    text := expandSnippetBody(item.body, A_Clipboard)
    if (text = "")           ; {input} をキャンセルしたとき
        return

    ; カーソル位置マーカー
    left := 0
    pos := InStr(text, "$|$")
    if pos {
        tail := SubStr(text, pos + 3)
        text := SubStr(text, 1, pos - 1) tail
        left := StrLen(StrReplace(tail, "`r`n", "`n"))
    }

    if (InStr(text, "`n") || StrLen(text) > 40) {
        A_Clipboard := text
        ClipWait(1)
        Send("^v")
        Sleep(200)
        A_Clipboard := clipBefore
    } else {
        SendText(text)
    }
    if left
        Send("{Left " left "}")
}

; {date:書式} {date} {clipboard} とパラメータ（{input} {textarea} {choice}）を置き換える。キャンセルは空文字
expandSnippetBody(body, clipText) {
    text := body
    while RegExMatch(text, "\{date(?::([^}]*))?\}", &m) {
        fmt := m[1] != "" ? m[1] : "yyyy/MM/dd"
        text := StrReplace(text, m[0], FormatTime(, fmt), , , 1)
    }
    text := StrReplace(text, "{clipboard}", clipText)

    ; パラメータを集める（出現順・名前で一意）
    fields := []
    seen := Map()
    pos := 1
    while (pos := RegExMatch(text, "\{(input|textarea|choice)(?::([^}=]*)(?:=([^}]*))?)?\}", &m, pos)) {
        pos += StrLen(m[0])
        kind := m[1]
        name := m[2] != "" ? m[2] : "入力"
        if seen.Has(name)
            continue
        seen[name] := true
        fields.Push({kind: kind, name: name, default: m[3], token: m[0]})
    }
    if !fields.Length
        return text

    values := askSnippetForm(fields, text)
    if !values.Count
        return ""
    for f in fields
        text := RegExReplace(text, "\{" f.kind "(?::" RegExEscape(f.name) "(?:=[^}]*)?)?\}", StrReplace(values[f.name], "$", "$$"))
    return text
}

RegExEscape(str) {
    return RegExReplace(str, "[\\.*?+^$|()\[\]{}]", "\$0")
}

; パラメータ入力フォーム。上にスニペット本文を表示し、下に欄を並べる。OK で Map(名前 -> 値)、キャンセルなら空の Map
askSnippetForm(fields, body) {
    values := Map()
    dlg := Gui("+AlwaysOnTop", "スニペット入力")
    dlg.SetFont("s10")
    dlg.Add("Text", "xm", "スニペット")
    dlg.Add("Edit", "xm w520 h140 ReadOnly", body)
    controls := Map()
    for f in fields {
        dlg.Add("Text", "xm", f.name)
        if (f.kind = "textarea")
            controls[f.name] := dlg.Add("Edit", "xm w520 h160 Multi WantTab", f.default)
        else if (f.kind = "choice") {
            options := StrSplit(f.default, "|")
            controls[f.name] := dlg.Add("DropDownList", "xm w520 Choose1", options)
        } else
            controls[f.name] := dlg.Add("Edit", "xm w520 -Multi", f.default)
    }
    ok := dlg.Add("Button", "xm Default w100", "OK")
    cancel := dlg.Add("Button", "x+10 w100", "キャンセル")
    submit(*) {
        for name, ctl in controls
            values[name] := ctl.Text
        dlg.Destroy()
    }
    ok.OnEvent("Click", submit)
    cancel.OnEvent("Click", (*) => dlg.Destroy())
    dlg.OnEvent("Close", (*) => dlg.Destroy())
    dlg.OnEvent("Escape", (*) => dlg.Destroy())
    dlg.Show()
    controls[fields[1].name].Focus()
    hwnd := dlg.Hwnd
    WinWaitClose("ahk_id " hwnd)
    return values
}

; Func メニュー用ハンドラー
handlerReloadSnippets(*) {
    loadSnippets(true)
}

handlerOpenSnippetsConfig(*) {
    if !FileExist(Constants.SNIPPETS_CONFIG)
        FileAppend("", Constants.SNIPPETS_CONFIG, "UTF-8")
    Run(Constants.SNIPPETS_CONFIG)
}

; ===========================================
; 検索窓（全スニペットをフィルタして選ぶ）
; ===========================================
class SnippetPicker {
    static win := 0            ; Gui（初回に作って使い回す）
    static filterBox := 0
    static listView := 0
    static previewBox := 0
    static rows := []          ; 一覧の行 -> {trigger, label, body}
    static target := 0         ; 貼り付け先ウィンドウ（開く直前のアクティブウィンドウ）
}

; 検索窓を開く。initialFilter はフィルタ欄の初期値（トリガー名など）
showSnippetPicker(initialFilter := "") {
    SnippetPicker.target := WinExist("A")
    if !SnippetPicker.win
        buildSnippetPicker()
    SnippetPicker.filterBox.Value := initialFilter
    refreshSnippetPicker()
    SnippetPicker.win.Show("w760")
    SnippetPicker.filterBox.Focus()
    Send("{End}")
}

buildSnippetPicker() {
    win := Gui("+AlwaysOnTop +Resize +MinSize600x400", "スニペット検索")
    win.SetFont("s10")
    win.Add("Text", , "絞り込み（空白区切りで AND。トリガー・ラベル・本文を対象）")
    filterBox := win.Add("Edit", "w740 -Multi")
    listView := win.Add("ListView", "w740 r10 -Multi Grid", ["トリガー", "ラベル", "本文"])
    previewBox := win.Add("Edit", "w740 r10 ReadOnly")
    win.Add("Text", , "↑↓ 選択 / Enter 貼り付け / Esc 閉じる")

    filterBox.OnEvent("Change", (*) => refreshSnippetPicker())
    listView.OnEvent("ItemFocus", (lv, row) => updateSnippetPreview(row))
    listView.OnEvent("DoubleClick", (lv, row) => chooseSnippetFromPicker())
    win.OnEvent("Escape", (*) => win.Hide())
    win.OnEvent("Close", (*) => win.Hide())
    win.OnEvent("Size", (g, minMax, w, h) => resizeSnippetPicker(w, h))

    ; 検索窓がアクティブなときだけ効くキー
    HotIfWinActive("ahk_id " win.Hwnd)
    Hotkey("Enter", (*) => chooseSnippetFromPicker())
    Hotkey("Down", (*) => moveSnippetSelection(1))
    Hotkey("Up", (*) => moveSnippetSelection(-1))
    HotIfWinActive()

    SnippetPicker.win := win
    SnippetPicker.filterBox := filterBox
    SnippetPicker.listView := listView
    SnippetPicker.previewBox := previewBox
}

resizeSnippetPicker(w, h) {
    m := 10
    SnippetPicker.filterBox.Move(, , w - m * 2)
    SnippetPicker.listView.GetPos(, &lvY)
    lvH := Round((h - lvY - 40) * 0.55)
    SnippetPicker.listView.Move(, , w - m * 2, lvH)
    SnippetPicker.previewBox.Move(, lvY + lvH + m, w - m * 2, Round((h - lvY - 40) * 0.45) - m * 2)
}

; フィルタに合う候補で一覧を作り直す
refreshSnippetPicker() {
    words := []
    for w in StrSplit(Trim(SnippetPicker.filterBox.Value), [" ", "　"])
        if (w != "")
            words.Push(w)
    lv := SnippetPicker.listView
    lv.Opt("-Redraw")
    lv.Delete()
    SnippetPicker.rows := []
    for trigger, list in SnippetStore.items {
        for item in list {
            if RegExMatch(item.body, "^\{search(?::(.*))?\}$")
                continue
            haystack := trigger " " item.label " " item.body
            hit := true
            for w in words
                if !InStr(haystack, w) {
                    hit := false
                    break
                }
            if !hit
                continue
            lv.Add("", trigger, item.label, snippetPreview(item.body))
            SnippetPicker.rows.Push(item)
        }
    }
    lv.ModifyCol(1, 90)
    lv.ModifyCol(2, 260)
    lv.ModifyCol(3, 360)
    lv.Opt("+Redraw")
    if SnippetPicker.rows.Length {
        lv.Modify(1, "Select Focus")
        updateSnippetPreview(1)
    } else
        SnippetPicker.previewBox.Value := ""
}

updateSnippetPreview(row) {
    if (row >= 1 && row <= SnippetPicker.rows.Length)
        SnippetPicker.previewBox.Value := SnippetPicker.rows[row].body
}

moveSnippetSelection(delta) {
    lv := SnippetPicker.listView
    count := SnippetPicker.rows.Length
    if !count
        return
    row := lv.GetNext() + delta
    row := row < 1 ? 1 : (row > count ? count : row)
    lv.Modify(row, "Select Focus Vis")
    updateSnippetPreview(row)
}

; 選択中の候補を貼り付け先に貼る
chooseSnippetFromPicker() {
    row := SnippetPicker.listView.GetNext()
    if (row < 1 || row > SnippetPicker.rows.Length)
        return
    item := SnippetPicker.rows[row]
    SnippetPicker.win.Hide()
    if SnippetPicker.target {
        WinActivate("ahk_id " SnippetPicker.target)
        WinWaitActive("ahk_id " SnippetPicker.target, , 1)
        Sleep(100)
    }
    snippetPaste(item)
}
