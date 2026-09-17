#NoEnv
SendMode Input
SetWorkingDir %A_ScriptDir%
CoordMode, Mouse, Screen
SetBatchLines, -1

; ============================================
; НАСТРОЙКИ АВТООБНОВЛЕНИЯ
; ============================================
global CurrentVersion := "1.0"
global UpdateUrl := "https://твой-сайт.com/latest_version.txt"
global ScriptUrl := "https://твой-сайт.com/Vozvraty.ahk"

; ============================================
; Проверка обновлений с уведомлением
; ============================================
CheckForUpdates()

CheckForUpdates() {
    try {
        whr := ComObjCreate("WinHttp.WinHttpRequest.5.1")
        whr.Open("GET", UpdateUrl, false)
        whr.Send()
        whr.WaitForResponse()
        NewVersion := Trim(whr.ResponseText)
    } catch {
        return
    }

    if (NewVersion = "" || NewVersion = CurrentVersion)
        return

    ; --- Уведомление ---
    TrayTip, Обновление, Найдена версия %NewVersion%. Обновляю..., 5, 1
    Sleep, 1500

    ; Скачиваем новую версию во временный файл
    tempScript := A_ScriptDir . "\" . A_ScriptName . ".new"
    FileDelete, %tempScript%
    UrlDownloadToFile, %ScriptUrl%, %tempScript%
    if ErrorLevel {
        TrayTip, Обновление, Ошибка загрузки. Продолжаю работу., 5, 3
        Sleep, 2000
        return
    }

    TrayTip, Обновление, Установка версии %NewVersion%..., 5, 1
    Sleep, 1000

    ; Создаём помощника, который подождёт закрытия скрипта и заменит файл
    helperPath := A_Temp . "\ahk_updater.ahk"
    FileDelete, %helperPath%

    helperCode := "
    ( LTrim
        Sleep, 800
        FileMove, %A_ScriptFullPath%, %A_ScriptDir%\%A_ScriptName%.old, 1
        FileMove, %tempScript%, %A_ScriptFullPath%, 1
        Run, %A_ScriptFullPath%
        ExitApp
    )"

    StringReplace, helperCode, helperCode, `%A_ScriptFullPath`%, %A_ScriptFullPath%, All
    StringReplace, helperCode, helperCode, `%A_ScriptDir`%, %A_ScriptDir%, All
    StringReplace, helperCode, helperCode, `%A_ScriptName`%, %A_ScriptName%, All
    StringReplace, helperCode, helperCode, `%tempScript`%, %tempScript%, All

    FileAppend, %helperCode%, %helperPath%
    Run, %helperPath%
    ExitApp
}

; ============================================
; Файл настроек
; ============================================
global SettingsFile := A_ScriptDir "\vozvraty.ini"
global SearchNumber := "66811"

if FileExist(SettingsFile) {
    IniRead, SavedNum, %SettingsFile%, Settings, SearchNumber, %A_Space%
    if (SavedNum != "" && SavedNum != "ERROR")
        SearchNumber := SavedNum
}

; ============================================
; Оверлей
; ============================================
global StatusText
global OverlayVisible := true

Gui, +AlwaysOnTop +ToolWindow -Caption +E0x20
Gui, Color, 1A1A1A
Gui, Font, s11 cWhite Bold, Segoe UI
Gui, Add, Text, x15 y12 w300 cLime, === БИНДЫ ===
Gui, Font, s10 cWhite Norm
Gui, Add, Text, x15 y42 w300, Ctrl + Numpad5 - Поиск по клиентскому
Gui, Add, Text, x15 y64 w300, Ctrl + Numpad7 - Поздний возврат 9
Gui, Add, Text, x15 y86 w300, Ctrl + Numpad8 - Поздний возврат 18
Gui, Add, Text, x15 y108 w300, Ctrl + Numpad9 - Поздний возврат 27
Gui, Add, Text, x15 y130 w300, Ctrl + Numpad0 - Изменить число
Gui, Add, Text, x15 y152 w300, Insert - Скрыть/Показать
Gui, Font, s11 cWhite Bold
Gui, Add, Text, x15 y182 w300 cLime, === СТАТУС ===
Gui, Font, s10 cYellow Norm
Gui, Add, Text, x15 y207 w300 vStatusText, Готов
Gui, Show, x0 y300 w330 h245 NoActivate, Overlay

UpdateOverlayPosition()
WinSet, Transparent, 128, Overlay

; Уведомление при запуске
TrayTip, Vozvraty, Скрипт запущен. Версия %CurrentVersion%, 3, 1
return

UpdateOverlayPosition() {
    SysGet, ScreenW, 0
    SysGet, ScreenH, 1
    posX := ScreenW - 350
    posY := (ScreenH - 245) // 2
    Gui, Show, x%posX% y%posY% w330 h245 NoActivate, Overlay
}

^Numpad0::
    InputBox, NewNum, Поиск, Введи число:, , 250, 130, , , , , %SearchNumber%
    if (ErrorLevel = 0 && NewNum != "") {
        SearchNumber := NewNum
        IniWrite, %SearchNumber%, %SettingsFile%, Settings, SearchNumber
        UpdateStatus("Сохранено: " SearchNumber)
        Sleep, 1500
        UpdateStatus("Готов")
    }
return

^Numpad5::
    SetKeyDelay, 50, 30
    UpdateStatus("Numpad5: Ctrl+N")
    SendInput, ^n
    Sleep, 50
    UpdateStatus("Numpad5: Down")
    SendInput, {Down}
    Sleep, 30
    UpdateStatus("Numpad5: Enter")
    SendInput, {Enter}
    Sleep, 50
    UpdateStatus("Numpad5: " SearchNumber)
    SendInput, %SearchNumber%
    Sleep, 40
    SendInput, {Enter}
    Sleep, 50
    UpdateStatus("Numpad5: Click")
    MouseClick, Left, 828, 143
    Sleep, 50
    SendInput, ^+{Left}
    Sleep, 30
    SendInput, {Delete}
    Sleep, 30
    SendInput, 3
    Sleep, 30
    SendInput, {Enter}
    Sleep, 30
    SendInput, {Enter}
    UpdateStatus("Numpad5: Готово")
    Sleep, 1000
    UpdateStatus("Готов")
return

DoRoutine(num) {
    SetKeyDelay, 80, 80
    Send, #{Up}
    Sleep, 60
    MouseClick, Left, 370, 877
    Sleep, 40
    MouseClick, Left, 352, 813
    Sleep, 40
    MouseClick, Left, 181, 951
    Sleep, 60
    Send, ^+{Left}
    Sleep, 30
    Send, {Delete}
    Sleep, 30
    SendInput, %num%
    Sleep, 50
    MouseClick, Left, 779, 914
    Sleep, 60
    ClipSaved := ClipboardAll
    Clipboard := "Поздний возврат"
    ClipWait, 1
    Send, ^v
    Sleep, 80
    Clipboard := ClipSaved
    Send, {Enter}
    Sleep, 50
    Send, {F10}
    Sleep, 1000
    UpdateStatus("Готов")
}

^Numpad7::
    UpdateStatus("Возврат 9")
    DoRoutine("9")
return

^Numpad8::
    UpdateStatus("Возврат 18")
    DoRoutine("18")
return

^Numpad9::
    UpdateStatus("Возврат 27")
    DoRoutine("27")
return

Insert::
    if (OverlayVisible) {
        Gui, Hide
        OverlayVisible := false
    } else {
        UpdateOverlayPosition()
        WinSet, Transparent, 128, Overlay
        OverlayVisible := true
    }
return

UpdateStatus(txt) {
    GuiControl,, StatusText, %txt%
}