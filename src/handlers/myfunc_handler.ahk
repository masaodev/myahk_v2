#Include ../config/constants.ahk
#Include ../utils/create_obsidian_url.ahk
#Include ../utils/create_shortcut.ahk

;; クリップボードのテキストから前後の空白を除去する
handlerDeleteEmpty(ItemName, ItemPos, MyMenu) {
    A_Clipboard := Trim(A_Clipboard," `t`r`n")
    TrayTip("空白を除去しました。")
}

;; クリップボードの各行の先頭に引用記号(> )を追加する
handlerAddQuote(ItemName, ItemPos, MyMenu) {
  result := ""
  Loop Parse A_Clipboard, "`n", "`r"
  {
    result := result . "> " . A_LoopField . "`r`n"
  }
  A_Clipboard := result
}

;; メール用にファイルパスを整形する（ディレクトリを<>で囲み、ファイル名をリスト化）
handlerFormatForMail(ItemName, ItemPos, MyMenu) {
  is_first:=true
  result := ""
  Loop Parse A_Clipboard, "`n", "`r"
  {
    var1 := Trim(A_LoopField," `t`r`n")
    var1 := StrReplace(var1, "file:///")
    SplitPath(var1, &name, &dir, &ext, &name_no_ext, &drive)
    if(is_first){
      result := "<" . dir . ">`r`n"
      is_first:=false
    }
    result := result . name . "`r`n"
    A_Clipboard := result
  }
}

;; クリップボードの各行をSQLのIN句の形式に変換する
handlerCreateSqlInsentence(ItemName, ItemPos, MyMenu) {
  result := "in ("
  Loop Parse Trim(A_Clipboard,"`r`n"), "`n", "`r"
  {
    result := result . "`r`n  '" . A_LoopField . "',"
  }
  result := SubStr(result, 1, StrLen(result)-1)
  result := result . "`r`n)"
  A_Clipboard := result
}

;; システムのゴミ箱を空にする
handlerFileRecycleEmpty(ItemName, ItemPos, MyMenu) {
  FileRecycleEmpty
  TrayTip("ゴミ箱を空にしました。")
}

;; クリップボードのテキストからObsidianのリンクを生成する
handlerCreateObsidianUrl(ItemName, ItemPos, MyMenu) {
    CreateObsidianUrl(A_Clipboard)
    TrayTip("Obsidianリンクを生成しました。")
}

;; ショートカットのリストア用テキストファイルからショートカットを復元する
handlerRestoreShortcutText(ItemName, ItemPos, MyMenu) {
  uidir := InputBox("出力先ディレクトリを選択してください。")
  uifile := InputBox("リストア用テキストファイル（shortcut_txt）を選択してください。")

  restoreShortcutText(uifile.value,uidir.value)
}

;; 指定されたディレクトリ内のショートカット情報をテキストファイルに出力する
handlerCreateShortcutText(ItemName, ItemPos, MyMenu) {
  uidir := InputBox("ショートカットが入っているディレクトリを選択してください。")
  uifile := InputBox("出力先フォルダを選択してください。")

  createShortcutText(uidir.value . "\*.lnk*", uifile.value . "\shortcut_txt.txt")
}

;; フォルダを選択して無効なショートカットを管理する
handlerManageSelectedFolderShortcuts(ItemName, ItemPos, MyMenu) {
    ; フォルダ選択ダイアログを表示
    selectedFolder := InputBox("管理するフォルダを入力してください。")
    
    if (selectedFolder.value == "") {
        return ; キャンセルされた場合
    }
    
    handleInvalidShortcutsManagement(selectedFolder.value, "無効なショートカット管理 - " . selectedFolder.value)
}

;; 無効なショートカットを管理する（削除・移動などのアクション）
handlerManageInvalidShortcuts(ItemName, ItemPos, MyMenu) {
    if (!DirExist(Constants.TOOL_FOLDER)) {
        MsgBox("ツールフォルダが存在しません: " . Constants.TOOL_FOLDER, "エラー", "IconX")
        return
    }
    
    handleInvalidShortcutsManagement(Constants.TOOL_FOLDER, "無効なショートカット管理")
}

;; クリップボードのファイルリストをバックアップする
handlerFileBackup(ItemName, ItemPos, MyMenu) {
    if (A_Clipboard == "") {
        TrayTip("エラー", "クリップボードが空です。")
        return
    }
    
    try {
        fileBackup(A_Clipboard)
        TrayTip("完了", "ファイルバックアップが完了しました。")
    } catch Error as e {
        TrayTip("エラー", "バックアップ中にエラーが発生しました: " . e.message)
    }
}

;ファイルバックアップ
fileBackup(backuplist) {
  is_first := true
  Loop Parse backuplist, "`n", "`r"
  {
    var1 := Trim(A_LoopField," `t`r`n")
    SplitPath(var1, &name, &dir, &ext, &name_no_ext, &drive)
    if(is_first){
      back := dir . "\bk"
      ; bkフォルダ作成
      if(!DirExist(back)) {
        DirCreate(back)
      }
      date_dir := back . "\" . A_YYYY . A_MM . A_DD
      if(!DirExist(date_dir)) {
        DirCreate(date_dir)
      }
      is_first := false
    }
    backup_file := back . "\" . A_YYYY . A_MM . A_DD . "\" . name
    if(FileExist(backup_file)) {
        FileMove(backup_file, backup_file . ".bak" . A_Hour . A_Min . A_Sec)
    }
    FileCopy(dir . "\" . name, back . "\" . A_YYYY . A_MM . A_DD)
  }
}

; URIデコードハンドラー
handlerDecodeURI(ItemName, ItemPos, MyMenu) {
  ; クリップボードの内容を取得
  originalText := A_Clipboard

  ; 空の場合は何もしない
  if (originalText = "") {
      MsgBox("クリップボードが空です。", "URIデコード", "OK Icon!")
      return
  }

  ; URIデコードを実行
  try {
      decodedText := DecodeUTF8URIComponent(originalText)

      ; 結果をクリップボードに設定
      A_Clipboard := decodedText

      ; 結果を表示（デバッグ用）
      if (originalText != decodedText) {
          MsgBox("URIデコードが完了しました。`n`n元のテキスト: " . originalText . "`n`nデコード結果: " . decodedText, "URIデコード", "OK Icon!")
      } else {
          MsgBox("デコードする文字が見つかりませんでした。`n`nテキスト: " . originalText, "URIデコード", "OK Icon!")
      }
  } catch Error as e {
      MsgBox("URIデコード中にエラーが発生しました: " . e.Message, "エラー", "OK Icon!")
  }
}

;; Git BashパスとWindowsパスを相互変換する
handlerConvertPath(ItemName, ItemPos, MyMenu) {
  originalPath := Trim(A_Clipboard)

  ; 空の場合は何もしない
  if (originalPath = "") {
      TrayTip("クリップボードが空です。")
      return
  }

  ; パス形式を判定して変換
  convertedPath := ""

  ; Git Bash形式かどうかチェック（例：/c/Users/... または /d/Projects/...）
  if (RegExMatch(originalPath, "^/([a-z])/(.*)$", &match)) {
      ; Git Bash → Windows
      driveLetter := StrUpper(match[1])
      restPath := StrReplace(match[2], "/", "\")
      convertedPath := driveLetter . ":\" . restPath
      conversionType := "Git Bash → Windows"
  }
  ; Windows形式かどうかチェック（例：C:\Users\... または D:\Projects\...）
  else if (RegExMatch(originalPath, "^([A-Za-z]):\\(.*)$", &match)) {
      ; Windows → Git Bash
      driveLetter := StrLower(match[1])
      restPath := StrReplace(match[2], "\", "/")
      convertedPath := "/" . driveLetter . "/" . restPath
      conversionType := "Windows → Git Bash"
  }
  else {
      TrayTip("パス形式を認識できませんでした。")
      return
  }

  ; 結果をクリップボードに設定
  A_Clipboard := convertedPath
  TrayTip("パス変換完了: " . conversionType)
}

;; WSLパスとWindowsパスを相互変換する
handlerConvertPathWSL(ItemName, ItemPos, MyMenu) {
  originalPath := Trim(A_Clipboard)

  ; 空の場合は何もしない
  if (originalPath = "") {
      TrayTip("クリップボードが空です。")
      return
  }

  ; パス形式を判定して変換
  convertedPath := ""

  ; WSL形式かどうかチェック（例：/mnt/c/Users/... または /mnt/d/Projects/...）
  if (RegExMatch(originalPath, "^/mnt/([a-z])/(.*)$", &match)) {
      ; WSL → Windows
      driveLetter := StrUpper(match[1])
      restPath := StrReplace(match[2], "/", "\")
      convertedPath := driveLetter . ":\" . restPath
      conversionType := "WSL → Windows"
  }
  ; Windows形式かどうかチェック（例：C:\Users\... または D:\Projects\...）
  else if (RegExMatch(originalPath, "^([A-Za-z]):\\(.*)$", &match)) {
      ; Windows → WSL
      driveLetter := StrLower(match[1])
      restPath := StrReplace(match[2], "\", "/")
      convertedPath := "/mnt/" . driveLetter . "/" . restPath
      conversionType := "Windows → WSL"
  }
  else {
      TrayTip("パス形式を認識できませんでした。")
      return
  }

  ; 結果をクリップボードに設定
  A_Clipboard := convertedPath
  TrayTip("パス変換完了: " . conversionType)
} 