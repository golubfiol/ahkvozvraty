#NoEnv
SendMode Input
SetWorkingDir %A_ScriptDir%
CoordMode, Mouse, Screen
SetBatchLines, -1

; ============================================
; НАСТРОЙКИ АВТООБНОВЛЕНИЯ
; ============================================
global CurrentVersion := "1.2"
global UpdateUrl := "https://raw.githubusercontent.com/golufbiol/ahkvozvraty/refs/heads/main/latest_version.txt"
global ScriptUrl := "https://raw.githubusercontent.com/golufbiol/ahkvozvraty/refs/heads/main/vozvraty.ahk"

CheckForUpdates()

CheckForUpdates() {
    try {
        whr := ComObjCreate("WinHttp.WinHttpRequest.5.1")
        whr.Open("GET", UpdateUrl, false)
        whr.Send()
        whr.WaitForResponse()
        NewVersion := whr.ResponseText
    } catch {
        return
    }

    NewVersion := RegExReplace(NewVersion, "[^\d\.]", "")
    NewVersion := Trim(NewVersion)

    if (NewVersion = "" || NewVersion = CurrentVersion)
        return

    TrayTip, Обновление, Найдена версия %NewVersion%. Обновляю..., 5, 1
    Sleep, 1500

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
global SearchNumber  := "66811"
global SearchNumber1 := "86958"

if FileExist(SettingsFile) {
    IniRead, SavedNum, %SettingsFile%, Settings, SearchNumber, %A_Space%
    if (SavedNum != "" && SavedNum != "ERROR")
        SearchNumber := SavedNum

    IniRead, SavedNum1, %SettingsFile%, Settings, SearchNumber1, %A_Space%
    if (SavedNum1 != "" && SavedNum1 != "ERROR")
        SearchNumber1 := SavedNum1
}

; ============================================
; Оверлей
; ============================================
global StatusText
global OverlayVisible := true

Gui, +AlwaysOnTop +ToolWindow -Caption +E0x20
Gui, Color, 1A1A1A
Gui, Font, s11 cWhite Bold, Segoe UI
Gui, Add, Text, x15 y12 w340 cLime, === БИНДЫ ===
Gui, Font, s10 cWhite Norm
Gui, Add, Text, x15 y42  w340, Ctrl + Numpad1 - Товар с реализации 1
Gui, Add, Text, x15 y64  w340, Ctrl + Numpad2 - Товар с реализации 2
Gui, Add, Text, x15 y86  w340, Ctrl + Numpad5 - Поиск по клиентскому
Gui, Add, Text, x15 y108 w340, Ctrl + Numpad7 - Поздний возврат 9
Gui, Add, Text, x15 y130 w340, Ctrl + Numpad8 - Поздний возврат 18
Gui, Add, Text, x15 y152 w340, Ctrl + Numpad9 - Поздний возврат 27
Gui, Add, Text, x15 y174 w340, Ctrl + Numpad0 - Изменить клиентский номер
Gui, Add, Text, x15 y196 w340, Insert - Скрыть/Показать
Gui, Font, s11 cWhite Bold
Gui, Add, Text, x15 y226 w340 cLime, === СТАТУС ===
Gui, Font, s10 cYellow Norm
Gui, Add, Text, x15 y251 w340 vStatusText, Готов
Gui, Show, x0 y300 w370 h290 NoActivate, Overlay

UpdateOverlayPosition()
WinSet, Transparent, 128, Overlay

TrayTip, Vozvraty, Скрипт запущен. Версия %CurrentVersion%, 3, 1
return

UpdateOverlayPosition() {
    SysGet, ScreenW, 0
    SysGet, ScreenH, 1
    posX := ScreenW - 390
    posY := (ScreenH - 290) // 2
    Gui, Show, x%posX% y%posY% w370 h290 NoActivate, Overlay
}

; ============================================
; Ctrl + Numpad0 - меню выбора
; ============================================
^Numpad0::
    Gui, ChangeNum:Destroy

    Gui, ChangeNum:+AlwaysOnTop +ToolWindow -Caption +E0x20
    Gui, ChangeNum:Color, 1A1A1A
    Gui, ChangeNum:Font, s11 cWhite Bold, Segoe UI
    Gui, ChangeNum:Add, Text, x20 y15 w280 cLime, Изменить число
    Gui, ChangeNum:Font, s9 cYellow Norm
    Gui, ChangeNum:Add, Text, x20 y45 w280, Текущие значения:
    Gui, ChangeNum:Font, s9 cWhite Norm
    Gui, ChangeNum:Add, Text, x20 y65 w280, Поиск по клиентскому: %SearchNumber%
    Gui, ChangeNum:Add, Text, x20 y85 w280, Товар с реализации: %SearchNumber1%
    Gui, ChangeNum:Font, s10 cWhite Bold
    Gui, ChangeNum:Add, Button, x20 y120 w130 h32 gChangeClient, Поиск
    Gui, ChangeNum:Add, Button, x160 y120 w140 h32 gChangeTovar, Товар с реализации
    Gui, ChangeNum:Add, Button, x20 y160 w280 h28 gChangeCancel, Отмена

    Gui, ChangeNum:Show, w320 h205, Изменить число
return

ChangeClient:
    Gui, ChangeNum:Destroy
    InputBox, NewNum, Поиск по клиентскому, Введи число для "Поиск по клиентскому":, , 260, 130, , , , , %SearchNumber%
    if (ErrorLevel = 0 && NewNum != "") {
        SearchNumber := NewNum
        IniWrite, %SearchNumber%, %SettingsFile%, Settings, SearchNumber
        UpdateStatus("Сохранено (клиентский): " SearchNumber)
        Sleep, 1500
        UpdateStatus("Готов")
    }
return

ChangeTovar:
    Gui, ChangeNum:Destroy
    InputBox, NewNum1, Товар с реализации, Введи число для "Товар с реализации":, , 260, 130, , , , , %SearchNumber1%
    if (ErrorLevel = 0 && NewNum1 != "") {
        SearchNumber1 := NewNum1
        IniWrite, %SearchNumber1%, %SettingsFile%, Settings, SearchNumber1
        UpdateStatus("Сохранено (товар): " SearchNumber1)
        Sleep, 1500
        UpdateStatus("Готов")
    }
return

ChangeCancel:
    Gui, ChangeNum:Destroy
return

; ============================================
; Ctrl + Numpad5 - Поиск по клиентскому
; ============================================
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
    UpdateStatus("Numpad5: Click 828,143")
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

; ============================================
; Ctrl + Numpad1 - Товар с реализации 1
; ============================================
^Numpad1::
    SetKeyDelay, 50, 30
    UpdateStatus("Numpad1: Ctrl+N")
    SendInput, ^n
    Sleep, 300
    UpdateStatus("Numpad1: Up")
    SendInput, {Up}
    Sleep, 200
    UpdateStatus("Numpad1: Click 865,367")
    MouseClick, Left, 865, 367
    Sleep, 300
    UpdateStatus("Numpad1: " SearchNumber1)
    SendInput, %SearchNumber1%
    Sleep, 150
    SendInput, {Enter}
    Sleep, 150
    UpdateStatus("Numpad1: Готово")
    Sleep, 800
    UpdateStatus("Готов")
return

; ============================================
; Ctrl + Numpad2 - Товар с реализации 2
; ============================================
^Numpad2::
    SetKeyDelay, 50, 30
    UpdateStatus("Numpad2: DoubleClick 980,310")
    MouseClick, Left, 980, 310, 2
    Sleep, 500

    UpdateStatus("Numpad2: Товар с реализации")
    ClipSaved := ClipboardAll
    Clipboard := "Товар с реализации"
    ClipWait, 1
    SendInput, ^v
    Sleep, 150
    Clipboard := ClipSaved

    UpdateStatus("Numpad2: Enter")
    SendInput, {Enter}
    Sleep, 200

    UpdateStatus("Numpad2: F10")
    SendInput, {F10}
    Sleep, 150
    UpdateStatus("Numpad2: Готово")
    Sleep, 800
    UpdateStatus("Готов")
return

; ============================================
; Ctrl + Numpad7 / 8 / 9 - Поздний возврат
; ============================================
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

; ============================================
; Insert - показать / скрыть оверлей
; ============================================
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
