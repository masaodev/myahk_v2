#Requires AutoHotkey v2.0

; ===========================================
; メインエントリーポイント
; ===========================================

; 依存関係のインクルード
#Include src/config/constants.ahk
#Include src/setup/initialization.ahk
#Include src/menu/menu_setup.ahk
#Include src/handlers/app_launcher.ahk
#Include src/utils/common_func.ahk
#Include src/handlers/myfunc_handler.ahk
#Include src/utils/create_shortcut.ahk
#Include src/utils/shortcut_validator.ahk
#Include src/handlers/shortcut_ui_handler.ahk

; ===========================================
; 初期化
; ===========================================
initializeApplication()

; ===========================================
; メインメニューとホットキー設定
; ===========================================

InstallKeybdHook()

; メインメニューを作成
myMenu := createMainMenu()
toolsMenu := createToolsMenu()
toolsMenuAll := createToolsAllMenu()
myFuncMenu := createFuncMenu()

; ホットキー設定
vk1C::myMenu.Show()                        ; 変換キー: メインメニュー表示
vk1D & t::toolsMenu.Show()               ; 無変換 + T: ツールメニュー
vk1D & a::toolsMenuAll.Show()            ; 無変換 + A: 全ツールメニュー
vk1D & s::myFuncMenu.show()               ; 無変換 + S: Funcメニュー

; メインメニューアクション項目のホットキーを設定ファイルから動的に登録
registerMainMenuHotkeys()