; ===========================================
; VirtualDesktopAccessor.dll ラッパークラス
; ===========================================
;
; 前提条件:
;   lib/VirtualDesktopAccessor.dll を配置すること
;   https://github.com/Ciantic/VirtualDesktopAccessor/releases

class VirtualDesktop {
    static _hModule := 0

    static Init() {
        dllPath := A_ScriptDir "\lib\VirtualDesktopAccessor.dll"
        if (!FileExist(dllPath)) {
            throw Error("VirtualDesktopAccessor.dll が見つかりません: " dllPath)
        }
        this._hModule := DllCall("LoadLibrary", "Str", dllPath, "Ptr")
        if (!this._hModule) {
            throw Error("VirtualDesktopAccessor.dll のロードに失敗しました")
        }
    }

    static GetCurrentDesktopNumber() {
        return DllCall("VirtualDesktopAccessor\GetCurrentDesktopNumber", "Int")
    }

    static GetDesktopCount() {
        return DllCall("VirtualDesktopAccessor\GetDesktopCount", "Int")
    }

    static GetWindowDesktopNumber(hwnd) {
        return DllCall("VirtualDesktopAccessor\GetWindowDesktopNumber", "Ptr", hwnd, "Int")
    }

    static MoveWindowToDesktopNumber(hwnd, desktopNumber) {
        return DllCall("VirtualDesktopAccessor\MoveWindowToDesktopNumber", "Ptr", hwnd, "Int", desktopNumber, "Int")
    }

    static GoToDesktopNumber(desktopNumber) {
        DllCall("VirtualDesktopAccessor\GoToDesktopNumber", "Int", desktopNumber)
    }

    ;; ウィンドウを隣接デスクトップへ移動（direction: 1=次, -1=前）
    ;; follow: trueの場合、移動先のデスクトップに切り替える
    static MoveWindowToAdjacentDesktop(hwnd, direction, follow := true) {
        current := this.GetWindowDesktopNumber(hwnd)
        count := this.GetDesktopCount()
        dest := Mod(current + direction + count, count)
        this.MoveWindowToDesktopNumber(hwnd, dest)
        if (follow) {
            this.GoToDesktopNumber(dest)
        }
        return dest
    }

    static PinWindow(hwnd) {
        DllCall("VirtualDesktopAccessor\PinWindow", "Ptr", hwnd)
    }

    static UnPinWindow(hwnd) {
        DllCall("VirtualDesktopAccessor\UnPinWindow", "Ptr", hwnd)
    }

    static IsPinnedWindow(hwnd) {
        return DllCall("VirtualDesktopAccessor\IsPinnedWindow", "Ptr", hwnd, "Int")
    }
}
