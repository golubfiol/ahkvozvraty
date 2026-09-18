#NoEnv
SendMode Input
SetWorkingDir %A_ScriptDir%
CoordMode, Mouse, Screen
SetBatchLines, -1

; ============================================
; НАСТРОЙКИ АВТООБНОВЛЕНИЯ
; ============================================
global CurrentVersion := "2.2"
global UpdateUrl := "https://raw.githubusercontent.com/golubfiol/ahkvozvraty/refs/heads/main/latest_version.txt"
global ScriptUrl := "https://raw.githubusercontent.com/golubfiol/ahkvozvraty/refs/heads/main/vozvraty.ahk"

; ============================================
; Файл настроек
; ============================================
global SettingsFile := A_ScriptDir . "\vozvraty.ini"
global SearchNumber  := "66811"
global SearchNumber1 := "86958"

; ============================================
; Состояние задачи
; ============================================
global CurrentTask := ""
global BlinkState  := false
global WaitText    := ""

; ============================================
; АВТОЗАПУСК
; ============================================
AddToStartup()

AddToStartup() {
    ahkPath := ""
    possiblePaths := []
    possiblePaths.Push(A_ProgramFiles . "\AutoHotkey\AutoHotkey.exe")
    possiblePaths.Push(A_ProgramFiles . "\AutoHotkey\v1.1.37.02\AutoHotkey.exe")
    possiblePaths.Push(A_ProgramFiles . "\AutoHotkey\v1.1.37.02\AutoHotkeyU64.exe")
    possiblePaths.Push("C:\Program Files\AutoHotkey\AutoHotkeyU64.exe")
    possiblePaths.Push("C:\Program Files (x86)\AutoHotkey\AutoHotkey.exe")
    possiblePaths.Push(A_WinDir . "\AutoHotkey.exe")

    for index, p in possiblePaths {
        if FileExist(p) {
            ahkPath := p
            break
        }
    }

    if (ahkPath = "") {
        TrayTip, Автозапуск, Не найден AutoHotkey.exe., 5, 3
        Sleep, 2000
        return
    }

    ExpectedValue := """" . ahkPath . """ """ . A_ScriptFullPath . """"
    RegRead, CurrentValue, HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run, Vozvraty

    if (CurrentValue = ExpectedValue)
        return

    RegWrite, REG_SZ, HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run, Vozvraty, %ExpectedValue%
    TrayTip, Автозапуск, Скрипт добавлен в автозагрузку., 3, 1
    Sleep, 1500
}

; ============================================
; Проверка обновлений
; ============================================
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
        TrayTip, Обновление, Ошибка загрузки., 5, 3
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
; Загрузка сохранённых чисел
; ============================================
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
Gui, Add, Text, x15 y15 w370 cLime, === БИНДЫ ===
Gui, Font, s10 cWhite Norm
Gui, Add, Text, x15 y45  w370, 1) Ctrl + Numpad1 - Товар с реализации
Gui, Add, Text, x15 y67  w370, 2) Ctrl + Numpad4 - 47
Gui, Add, Text, x15 y89  w370, 3) Ctrl + Numpad5 - Поиск по клиентскому
Gui, Add, Text, x15 y111 w370, 4) Ctrl + Numpad7 - Поздний возврат 9
Gui, Add, Text, x15 y133 w370, 5) Ctrl + Numpad8 - Поздний возврат 18
Gui, Add, Text, x15 y155 w370, 6) Ctrl + Numpad9 - Поздний возврат 27
Gui, Add, Text, x15 y177 w370, 7) Ctrl + Numpad0 - Изменить клиентский номер
Gui, Add, Text, x15 y199 w370, 8) Ctrl + Numpad+ - Продолжить задачу реализация/47
Gui, Add, Text, x15 y221 w370, 9) Ctrl + Numpad- - Сброс
Gui, Add, Text, x15 y243 w370, 10) Insert - Скрыть/Показать
Gui, Add, Text, x15 y265 w370, 11) End - Закрыть ахк

Gui, Font, s11 cWhite Bold, Segoe UI
Gui, Add, Text, x15 y301 w370 cLime, === СТАТУС ===
Gui, Font, s10 cYellow Norm
Gui, Add, Text, x15 y326 w370 vStatusText, Готов

Gui, Show, x0 y300 w400 h367 NoActivate, Overlay

UpdateOverlayPosition()
WinSet, Transparent, 128, Overlay

TrayTip, Vozvraty, Скрипт запущен. Версия %CurrentVersion%, 3, 1

SetTimer, BlinkWait, 600
return

UpdateOverlayPosition() {
    SysGet, ScreenW, 0
    SysGet, ScreenH, 1
    posX := ScreenW - 420
    posY := (ScreenH - 367) // 2
    Gui, Show, x%posX% y%posY% w400 h367 NoActivate, Overlay
}

; ============================================
; Индикатор ожидания
; ============================================
BlinkWait:
    if (CurrentTask = "") {
        return
    }
    BlinkState := !BlinkState
    if (BlinkState) {
        UpdateStatus(">>> " WaitText " <<<")
    } else {
        UpdateStatus(" ")
    }
return

; ============================================
; End — закрыть скрипт полностью
; ============================================
End::
    ExitApp
return

; ============================================
; Ctrl + Numpad- (минус) — сброс
; ============================================
^NumpadSub::
    CurrentTask := ""
    WaitText := ""
    UpdateStatus("Сброшено. Готов к новой задаче.")
    Sleep, 1500
    UpdateStatus("Готов")
return

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
    InputBox, NewNum, Поиск по клиентскому, Введи число:, , 260, 130, , , , , %SearchNumber%
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
    InputBox, NewNum1, Товар с реализации, Введи число:, , 260, 130, , , , , %SearchNumber1%
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
; Ctrl + Numpad1 — задача 1, часть 1
; ============================================
^Numpad1::
    CurrentTask := "1"
    WaitText := "Ожидание реализация"
    SetKeyDelay, 30, 20
    UpdateStatus("Товар с реализации: часть 1...")

    SendInput, ^n
    Sleep, 50
    SendInput, {Up}
    Sleep, 50
    MouseClick, Left, 865, 367
    Sleep, 50
    SendInput, %SearchNumber1%
    Sleep, 50
    SendInput, {Enter}
    Sleep, 50
return

; ============================================
; Ctrl + Numpad4 — задача 4, часть 1
; ============================================
^Numpad4::
    CurrentTask := "4"
    WaitText := "Ожидание 47"
    SetKeyDelay, 30, 20
    UpdateStatus("47: часть 1...")

    SendInput, ^n
    Sleep, 50
    SendInput, {Tab}
    Sleep, 50
    SendInput, {Enter}
    Sleep, 50
    ClipSaved := ClipboardAll
Clipboard := "%Василия петушкова, 25%"
ClipWait, 1
SendInput, ^v
Sleep, 50
Clipboard := ClipSaved
    Sleep, 50
    SendInput, {Enter}
    Sleep, 50
    MouseClick, Left, 833, 143
    Sleep, 50
    SendInput, ^+{Left}
    Sleep, 50
    SendInput, 3
    Sleep, 50
    MouseClick, Left, 274, 126
    Sleep, 50
return

; ============================================
; Ctrl + Numpad+ — продолжение задачи
; ============================================
^NumpadAdd::
    if (CurrentTask = "1") {
        UpdateStatus("Продолжение: Товар с реализации...")
        SetKeyDelay, 30, 20

        MouseClick, Left, 980, 310, 2
        Sleep, 50

        ClipSaved := ClipboardAll
        Clipboard := "Товар с реализации"
        ClipWait, 1
        SendInput, ^v
        Sleep, 50
        Clipboard := ClipSaved

        SendInput, {Enter}
        Sleep, 50

        SendInput, {F10}
        Sleep, 50

        CurrentTask := ""
        WaitText := ""
        UpdateStatus("Задача завершена")
        Sleep, 1200
        UpdateStatus("Готов")
    }
    else if (CurrentTask = "4") {
        UpdateStatus("Продолжение: 47...")
        SetKeyDelay, 30, 20

        Send, #{Up}
        Sleep, 50

        MouseClick, Left, 321, 882
        Sleep, 50
        MouseClick, Left, 256, 795
        Sleep, 50
        MouseClick, Left, 174, 947
        Sleep, 50
        Send, ^+{Left}
        Sleep, 50
        SendInput, 0
        Sleep, 50
        SendInput, {F10}
        Sleep, 50

        CurrentTask := ""
        WaitText := ""
        UpdateStatus("Задача завершена")
        Sleep, 1200
        UpdateStatus("Готов")
    }
    else {
        UpdateStatus("Нет активной задачи. Нажми Ctrl+Numpad1 или Ctrl+Numpad4")
        Sleep, 1500
        UpdateStatus("Готов")
    }
return

; ============================================
; Ctrl + Numpad5 - Поиск по клиентскому
; ============================================
^Numpad5::
    SetKeyDelay, 30, 20
    UpdateStatus("Numpad5: Ctrl+N")
    SendInput, ^n
    Sleep, 50
    SendInput, {Down}
    Sleep, 50
    SendInput, {Enter}
    Sleep, 50
    SendInput, %SearchNumber%
    Sleep, 50
    SendInput, {Enter}
    Sleep, 50
    MouseClick, Left, 828, 143
    Sleep, 50
    SendInput, ^+{Left}
    Sleep, 50
    SendInput, {Delete}
    Sleep, 50
    SendInput, 3
    Sleep, 50
    SendInput, {Enter}
    Sleep, 50
    SendInput, {Enter}
    UpdateStatus("Numpad5: Готово")
    Sleep, 800
    UpdateStatus("Готов")
return

; ============================================
; Ctrl + Numpad7 / 8 / 9 - Поздний возврат
; ============================================
DoRoutine(num) {
    SetKeyDelay, 30, 20
    Send, #{Up}
    Sleep, 50
    MouseClick, Left, 370, 877
    Sleep, 50
    MouseClick, Left, 352, 813
    Sleep, 50
    MouseClick, Left, 181, 951
    Sleep, 50
    Send, ^+{Left}
    Sleep, 50
    Send, {Delete}
    Sleep, 50
    SendInput, %num%
    Sleep, 50
    MouseClick, Left, 779, 914
    Sleep, 50
    ClipSaved := ClipboardAll
    Clipboard := "Поздний возврат"
    ClipWait, 1
    Send, ^v
    Sleep, 50
    Clipboard := ClipSaved
    Send, {Enter}
    Sleep, 50
    Send, {F10}
    Sleep, 800
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
