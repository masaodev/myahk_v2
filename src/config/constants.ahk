; ===========================================
; 設定ファイル - 定数とフォルダパス定義
; ===========================================

class Constants {
    ; フォルダパス
    static BACKUP_FOLDER := A_WorkingDir "\backup"
    static USER_PROFILE := EnvGet("USERPROFILE")
    static MYAHK_V2_FOLDER := Constants.USER_PROFILE "\.myahk_v2"
    static TOOL_FOLDER := Constants.USER_PROFILE "\.myahk_v2\tools"
    static WORK_DIR := Constants.USER_PROFILE "\.myahk_v2\work_dir"
    static BACKUP_TOOLS_FOLDER := Constants.BACKUP_FOLDER "\tools"

    ; 設定ファイル
    static TOOLS_MENU_CONFIG := Constants.MYAHK_V2_FOLDER "\tools_menu.txt"
    static MAIN_MENU_CONFIG := Constants.MYAHK_V2_FOLDER "\main_menu.txt"
    static USER_CONFIG := Constants.MYAHK_V2_FOLDER "\user_config.ini"

    ; ユーザー設定（INIファイルから読み込み、デフォルト値あり）
    static OBSIDIAN_VAULT := Constants._ReadUserConfig("Obsidian", "vault", "obsidian-work")
    static TEMP_MEMO_PATH := Constants._ExpandPath(
        Constants._ReadUserConfig("Paths", "temp_memo", "%USERPROFILE%\.myahk_v2\一時メモ.txt")
    )

    ; Obsidian URI
    static OBSIDIAN_OPEN_URI := "obsidian://open?vault=" . Constants.OBSIDIAN_VAULT
    static OBSIDIAN_SWITCHER_URI := "obsidian://advanced-uri?vault=" . Constants.OBSIDIAN_VAULT . "&commandid=switcher%253Aopen"
    static OBSIDIAN_MEMOS_THINO_URI := "obsidian://advanced-uri?vault=" . Constants.OBSIDIAN_VAULT . "&commandid=obsidian-memos:open-thino-in-float"

    ; ユーザー設定を読み込むヘルパー関数（UTF-8対応）
    static _ReadUserConfig(section, key, default) {
        if !FileExist(Constants.USER_CONFIG) {
            return default
        }

        try {
            ; UTF-8として読み込む
            fileContent := FileRead(Constants.USER_CONFIG, "UTF-8")
            currentSection := ""

            Loop Parse, fileContent, "`n", "`r" {
                line := Trim(A_LoopField)

                ; 空行とコメント行をスキップ
                if (line == "" || SubStr(line, 1, 1) == ";") {
                    continue
                }

                ; セクション: [section]
                if (RegExMatch(line, "^\[(.*)\]$", &match)) {
                    currentSection := match[1]
                    continue
                }

                ; キー=値 の形式
                if (currentSection == section && InStr(line, "=")) {
                    parts := StrSplit(line, "=", , 2)
                    if (Trim(parts[1]) == key) {
                        return Trim(parts[2])
                    }
                }
            }
        } catch {
            ; エラー時はデフォルト値を返す
            return default
        }

        return default
    }

    ; パス内の環境変数を展開するヘルパー関数
    static _ExpandPath(path) {
        ; %USERPROFILE% を展開
        path := StrReplace(path, "%USERPROFILE%", Constants.USER_PROFILE)
        return path
    }
} 