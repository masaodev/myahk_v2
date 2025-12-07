; フォルダが存在しない場合は作成する
createFolderWhenNotExists(folder) {
    if(!FileExist(folder)) {
        DirCreate(folder)
    }
    return
}

; 指定フォルダの直下にある空フォルダのみを削除する関数
removeEmptyFolders(Folder) {
    Loop Files, Folder "\*", "D" { ; "D"オプションでディレクトリのみ対象
        ; フォルダ内のファイルとサブフォルダが存在するかチェック
        isEmpty := True
        Loop Files, A_LoopFileFullPath "\*.*", "FD" { ; サブフォルダとファイルを含む
            isEmpty := False
            break ; 1つでも存在すれば空ではないと判断
        }
        ; 空フォルダであれば削除
        if (isEmpty) {
            DirDelete(A_LoopFileFullPath)
        }
    }
}

; 無変換 + Q
; 作業フォルダ(work_dir)を開く
openWordDir(work_dir) {
    timeString := FormatTime(,"yyyyMMdd")
    param := work_dir . "\" . timeString
    createFolderWhenNotExists(param)
    ; Shiftキーが押されていない場合のみクリップボードにコピー
    if (!GetKeyState("Shift", "P")) {
        A_Clipboard := param
    }
    Run param
}

; クリップボードをテキスト化してペースト
pasteText(clipstr) {
    A_Clipboard := A_Clipboard
    Send("^v")
}

; いろいろなパスを開く
openAny(anyPath) {
    trimmedPath := Trim(anyPath, "<> `t`r`n　")
    ; パスがフォルダの場合
    if (isFolderExist(trimmedPath)) {
        ; そのまま開く
        Run(trimmedPath)
        return
    }

    ; パスがファイルの場合
    if (isFileExist(trimmedPath)) {
        SplitPath(trimmedPath, &name, &dir, &ext, &name_no_ext, &drive)
        ; 親フォルダを開く
        Run(dir)
        return
    }
    
    ; URLならそのまま（プラウザで）開く
    if (RegExMatch(trimmedPath, "http[s]?:.*")) {
        Run(trimmedPath)
        return
    }
    
    ; それ以外の場合はChromeでグーグル検索
    Run("http://www.google.co.jp/search?hl=ja&lr=lang_ja&ie=UTF-8&q=" . trimmedPath )

}

; フォルダが存在するかチェック
isFolderExist(path) {
    return FileExist(path) == "D"
}

; ファイルが存在するかチェック
isFileExist(path) {
    atte := (FileExist(path) and !isFolderExist(path))
    return atte
}

; .lnkファイルのターゲットパスを取得する関数
getLnkTarget(filePath) {
    ; Create a Shell objecta
    FileGetShortcut filePath, &OutTarget, &OutDir, &OutArgs, &OutDesc, &OutIcon, &OutIconNum, &OutRunState
    return OutTarget
    ; Return the target path
}
