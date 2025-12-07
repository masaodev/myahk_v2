#Requires AutoHotkey v2.0

;
; 以下、関数定義uidir
;

;; ターゲットフォルダにあるショートカットをテキストファイル化
createShortcutText(targetDir,textFilePath) {
    Loop Files, targetDir
    {
        FileGetShortcut(A_LoopFileFullPath, &target, &WorkingDir, &Args, &Description, &IconFile, &IconNum, &RunState)
        FileAppend(target . "`t" . A_LoopFileName . "`n",textFilePath)
    }
}

restoreShortcutText(textFilePath,outputDirectory) {
    message := ""
    text := FileRead(textFilePath)
    lines := StrSplit(text, "`n")
    for line in lines {
        str := StrSplit(line, "`t")  ; タブで分割
        FileCreateShortcut(str[1], outputDirectory . "\" . str[2],getParentDir(str[1]))
    }
    ;MsgBox("ショートカット先が存在しないもの一覧`r`n" message)
}

getParentDir(fullFileName) {
    SplitPath(fullFileName, &name, &dir, &ext, &name_no_ext, &drive)
    return dir
}
