#NoEnv
SendMode Input
SetWorkingDir %A_ScriptDir%
CoordMode, Mouse, Screen
SetBatchLines, -1

; ============================================
; НАСТРОЙКИ АВТООБНОВЛЕНИЯ
; ============================================
global CurrentVersion := "3.7"
global UpdateUrl := "https://raw.githubusercontent.com/golubfiol/ahkvozvraty/refs/heads/main/latest_version.txt"
global ScriptUrl := "https://raw.githubusercontent.com/golubfiol/ahkvozvraty/refs/heads/main/vozvraty.ahk"

; ============================================
; Файл настроек
; ============================================
global SettingsFile := A_ScriptDir . "\vozvraty.ini"
global SearchNumber  := "66811"
global SearchNumber1 := "86958"

global F5_ClientNumber  := ""
global F5_Months        := ""
global F5_UsePercent    := 0
global F5_Percent       := ""
global F5_UseComment    := 0
global F5_Comment       := ""

; ============================================
; Состояние задачи
; ============================================
global CurrentTask := ""
global BlinkState  := false
global WaitText    := ""

; ============================================
; Профиль
; ============================================
global Profile := "Отдел возвратов"

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

    try {
        whr2 := ComObjCreate("WinHttp.WinHttpRequest.5.1")
        whr2.Open("GET", ScriptUrl, false)
        whr2.Send()
        whr2.WaitForResponse()
        ScriptContent := whr2.ResponseText
    } catch {
        TrayTip, Обновление, Ошибка загрузки скрипта., 5, 3
        Sleep, 2000
        return
    }

    if (ScriptContent = "") {
        TrayTip, Обновление, Пустой ответ сервера., 5, 3
        Sleep, 2000
        return
    }

    if (SubStr(ScriptContent, 1, 1) = Chr(0xFEFF))
        ScriptContent := SubStr(ScriptContent, 2)

    tempScript := A_ScriptDir . "\" . A_ScriptName . ".new"
    FileDelete, %tempScript%
    FileAppend, %ScriptContent%, %tempScript%, UTF-8

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
; Загрузка настроек
; ============================================
if FileExist(SettingsFile) {
    IniRead, SavedNum, %SettingsFile%, Settings, SearchNumber, %A_Space%
    if (SavedNum != "" && SavedNum != "ERROR")
        SearchNumber := SavedNum

    IniRead, SavedNum1, %SettingsFile%, Settings, SearchNumber1, %A_Space%
    if (SavedNum1 != "" && SavedNum1 != "ERROR")
        SearchNumber1 := SavedNum1

    IniRead, v, %SettingsFile%, Special, ClientNumber, %A_Space%
    if (v != "" && v != "ERROR")
        F5_ClientNumber := v

    IniRead, v, %SettingsFile%, Special, Months, %A_Space%
    if (v != "" && v != "ERROR")
        F5_Months := v

    IniRead, v, %SettingsFile%, Special, UsePercent, 0
    F5_UsePercent := v

    IniRead, v, %SettingsFile%, Special, Percent, %A_Space%
    if (v != "" && v != "ERROR")
        F5_Percent := v

    IniRead, v, %SettingsFile%, Special, UseComment, 0
    F5_UseComment := v

    IniRead, v, %SettingsFile%, Special, Comment, %A_Space%
    if (v != "" && v != "ERROR")
        F5_Comment := v

    IniRead, v, %SettingsFile%, Settings, Profile, %A_Space%
    if (v = "Отдел возвратов" || v = "Дека")
        Profile := v
    else
        IniWrite, %Profile%, %SettingsFile%, Settings, Profile
}
else {
    IniWrite, %Profile%, %SettingsFile%, Settings, Profile
}

; ============================================
; Оверлей
; ============================================
global StatusText
global OverlayVisible := true

BuildOverlay()
return

BuildOverlay() {
    global Profile

    Gui, Main:Destroy
    Gui, Main:+AlwaysOnTop +ToolWindow -Caption +E0x20
    Gui, Main:Color, 1A1A1A

    Gui, Main:Font, s11 cWhite Bold, Segoe UI
    Gui, Main:Add, Text, x15 y15 w400, Активный профиль: %Profile%
    Gui, Main:Add, Text, x15 y40 w400 cAqua, Ctrl + Numpad/ - Сменить профиль

    Gui, Main:Font, s10 cWhite Norm
    Gui, Main:Add, Text, x15 y75 w400 cLime, === БИНДЫ ===

    yPos := 100
    if (Profile = "Отдел возвратов") {
        Gui, Main:Add, Text, x15 y%yPos% w400, 1) Ctrl + Numpad1 - Товар с реализации
        yPos += 22
        Gui, Main:Add, Text, x15 y%yPos% w400, 2) Ctrl + Numpad4 - 47
        yPos += 22
        Gui, Main:Add, Text, x15 y%yPos% w400, 3) Ctrl + F5 - Особый случай
        yPos += 22
        Gui, Main:Add, Text, x15 y%yPos% w400, 4) Ctrl + Numpad5 - Поиск по клиентскому
        yPos += 22
        Gui, Main:Add, Text, x15 y%yPos% w400, 5) Ctrl + Numpad7 - Поздний возврат 9
        yPos += 22
        Gui, Main:Add, Text, x15 y%yPos% w400, 6) Ctrl + Numpad8 - Поздний возврат 18
        yPos += 22
        Gui, Main:Add, Text, x15 y%yPos% w400, 7) Ctrl + Numpad9 - Поздний возврат 27
        yPos += 22
        Gui, Main:Add, Text, x15 y%yPos% w400, 8) Ctrl + Numpad0 - Изменить клиентский номер
        yPos += 22
        Gui, Main:Add, Text, x15 y%yPos% w400, 9) Ctrl + Numpad+ - Продолжить задачу 1/4/F5
        yPos += 22
        Gui, Main:Add, Text, x15 y%yPos% w400, 10) Ctrl + Numpad- - Сброс
        yPos += 22
        Gui, Main:Add, Text, x15 y%yPos% w400, 11) Insert - Скрыть/Показать
        yPos += 22
        Gui, Main:Add, Text, x15 y%yPos% w400, 12) Home - Перезапуск AHK
        yPos += 22
        Gui, Main:Add, Text, x15 y%yPos% w400, 13) End - Закрыть ахк
        yPos += 22
    }
    else if (Profile = "Дека") {
        Gui, Main:Add, Text, x15 y%yPos% w400, 1) Ctrl + Numpad1 - Создать список v-склады
        yPos += 22
        Gui, Main:Add, Text, x15 y%yPos% w400, 2) Ctrl + Numpad7 - Вставить код 1
        yPos += 22
        Gui, Main:Add, Text, x15 y%yPos% w400, 3) Ctrl + Numpad8 - Вставить код 2
        yPos += 22
        Gui, Main:Add, Text, x15 y%yPos% w400, 4) Ctrl + Numpad/ - Сменить профиль
        yPos += 22
        Gui, Main:Add, Text, x15 y%yPos% w400, 5) Insert - Скрыть/Показать
        yPos += 22
        Gui, Main:Add, Text, x15 y%yPos% w400, 6) Home - Перезапуск AHK
        yPos += 22
        Gui, Main:Add, Text, x15 y%yPos% w400, 7) End - Закрыть ахк
        yPos += 22
    }

    yPos += 10
    Gui, Main:Font, s11 cWhite Bold, Segoe UI
    Gui, Main:Add, Text, x15 y%yPos% w400 cLime, === СТАТУС ===
    yPos += 25
    Gui, Main:Font, s10 cYellow Norm
    Gui, Main:Add, Text, x15 y%yPos% w400 vStatusText, Готов

    winW := 430
    winH := yPos + 35

    Gui, Main:Show, x0 y0 w%winW% h%winH% NoActivate, Overlay
    Sleep, 30

    SysGet, ScreenW, 0
    SysGet, ScreenH, 1
    posX := ScreenW - winW - 20
    posY := (ScreenH - winH) // 2
    Gui, Main:Show, x%posX% y%posY% w%winW% h%winH% NoActivate, Overlay

    WinSet, Transparent, 128, Main
}

; ============================================
; Индикатор ожидания
; ============================================
SetTimer, BlinkWait, 600
return

BlinkWait:
    if (CurrentTask = "") {
        return
    }
    BlinkState := !BlinkState
    if (BlinkState) {
        UpdateStatus(">>> " . WaitText . " <<<")
    } else {
        UpdateStatus(" ")
    }
return

; ============================================
; Ctrl + Numpad/ — смена профиля
; ============================================
^NumpadDiv::
    if (Profile = "Отдел возвратов") {
        Profile := "Дека"
    } else {
        Profile := "Отдел возвратов"
    }
    IniWrite, %Profile%, %SettingsFile%, Settings, Profile
    TrayTip, Профиль, Активен: %Profile%, 3, 1
    BuildOverlay()
return

; ============================================
; Home — перезапуск с проверкой обновлений
; ============================================
Home::
    TrayTip, Vozvraty, Перезапуск скрипта..., 3, 1
    Sleep, 800
    Reload
return

; ============================================
; End — закрыть скрипт полностью
; ============================================
End::
    ExitApp
return

; ============================================
; Ctrl + Numpad- — сброс
; ============================================
^NumpadSub::
    if (Profile != "Отдел возвратов")
        return
    CurrentTask := ""
    WaitText := ""
    UpdateStatus("Сброшено. Готов к новой задаче.")
    Sleep, 1500
    UpdateStatus("Готов")
return

; ============================================
; Ctrl + Numpad0 — меню выбора
; ============================================
^Numpad0::
    if (Profile != "Отдел возвратов")
        return
    Gui, ChangeNum:Destroy

    Gui, ChangeNum:+AlwaysOnTop +ToolWindow -Caption +E0x20
    Gui, ChangeNum:Color, 1A1A1A
    Gui, ChangeNum:Font, s11 cWhite Bold, Segoe UI
    Gui, ChangeNum:Add, Text, x20 y15 w300 cLime, Изменить число
    Gui, ChangeNum:Font, s9 cYellow Norm
    Gui, ChangeNum:Add, Text, x20 y45 w300, Текущие значения:
    Gui, ChangeNum:Font, s9 cWhite Norm
    Gui, ChangeNum:Add, Text, x20 y65 w300, Поиск по клиентскому: %SearchNumber%
    Gui, ChangeNum:Add, Text, x20 y85 w300, Товар с реализации: %SearchNumber1%
    Gui, ChangeNum:Font, s10 cWhite Bold
    Gui, ChangeNum:Add, Button, x20 y120 w130 h32 gChangeClient, Поиск
    Gui, ChangeNum:Add, Button, x160 y120 w140 h32 gChangeTovar, Товар с реализации
    Gui, ChangeNum:Add, Button, x20 y160 w300 h32 gChangeSpecial, Особый случай
    Gui, ChangeNum:Add, Button, x20 y200 w300 h28 gChangeCancel, Отмена

    Gui, ChangeNum:Show, w340 h245, Изменить число
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

ChangeSpecial:
    Gui, ChangeNum:Destroy
    ShowSpecialDialog()
return

; ============================================
; Особый случай — окно
; ============================================
ShowSpecialDialog() {
    global F5_ClientNumber, F5_Months, F5_UsePercent, F5_Percent, F5_UseComment, F5_Comment

    Gui, Special:Destroy
    Gui, Special:+AlwaysOnTop +ToolWindow -Caption +E0x20
    Gui, Special:Color, 1A1A1A
    Gui, Special:Font, s11 cWhite Bold, Segoe UI
    Gui, Special:Add, Text, x20 y15 w420 cLime, Особый случай (Ctrl+F5)

    Gui, Special:Font, s10 cWhite Norm, Segoe UI
    Gui, Special:Add, Text, x20 y50 w200, Клиентский номер:

    Gui, Special:Font, s10 cBlack Norm, Segoe UI
    Gui, Special:Add, Edit, x230 y47 w200 vSpecClient, %F5_ClientNumber%

    Gui, Special:Font, s10 cWhite Norm, Segoe UI
    Gui, Special:Add, Text, x20 y80 w200, Количество месяцев:

    Gui, Special:Font, s10 cBlack Norm, Segoe UI
    Gui, Special:Add, Edit, x230 y77 w200 vSpecMonths, %F5_Months%

    Gui, Special:Font, s10 cWhite Norm, Segoe UI
    Gui, Special:Add, Checkbox, x20 y115 w400 vSpecUsePercent gTogglePercent Checked%F5_UsePercent%, Изменить дефолтный процент
    Gui, Special:Add, Text, x40 y145 w190, Процент:

    Gui, Special:Font, s10 cBlack Norm, Segoe UI
    Gui, Special:Add, Edit, x230 y142 w200 vSpecPercent, %F5_Percent%

    Gui, Special:Font, s10 cWhite Norm, Segoe UI
    Gui, Special:Add, Checkbox, x20 y180 w400 vSpecUseComment gToggleComment Checked%F5_UseComment%, Добавить комментарий
    Gui, Special:Add, Text, x40 y210 w190, Комментарий:

    Gui, Special:Font, s10 cBlack Norm, Segoe UI
    Gui, Special:Add, Edit, x230 y207 w200 vSpecComment, %F5_Comment%

    Gui, Special:Font, s10 cWhite Bold, Segoe UI
    Gui, Special:Add, Button, x230 y250 w200 h32 gSpecSave, Сохранить
    Gui, Special:Add, Button, x20 y250 w200 h32 gSpecCancel, Отмена

    Gui, Special:Show, w450 h300, Особый случай

    ApplySpecialEnabledState()
}

ApplySpecialEnabledState() {
    GuiControlGet, pState,, SpecUsePercent
    GuiControlGet, cState,, SpecUseComment

    if (pState)
        GuiControl, Special:Enable, SpecPercent
    else
        GuiControl, Special:Disable, SpecPercent

    if (cState)
        GuiControl, Special:Enable, SpecComment
    else
        GuiControl, Special:Disable, SpecComment
}

TogglePercent:
    ApplySpecialEnabledState()
return

ToggleComment:
    ApplySpecialEnabledState()
return

SpecSave:
    Gui, Special:Submit, NoHide
    F5_ClientNumber := SpecClient
    F5_Months       := SpecMonths
    F5_UsePercent   := SpecUsePercent
    F5_Percent      := SpecPercent
    F5_UseComment   := SpecUseComment
    F5_Comment      := SpecComment

    IniWrite, %F5_ClientNumber%, %SettingsFile%, Special, ClientNumber
    IniWrite, %F5_Months%,       %SettingsFile%, Special, Months
    IniWrite, %F5_UsePercent%,   %SettingsFile%, Special, UsePercent
    IniWrite, %F5_Percent%,      %SettingsFile%, Special, Percent
    IniWrite, %F5_UseComment%,   %SettingsFile%, Special, UseComment
    IniWrite, %F5_Comment%,      %SettingsFile%, Special, Comment

    Gui, Special:Destroy
    UpdateStatus("Особый случай сохранён")
    Sleep, 1200
    UpdateStatus("Готов")
return

SpecCancel:
    Gui, Special:Destroy
return

; ============================================
; Ctrl + F5 — Особый случай, часть 1
; ============================================
^F5::
    if (Profile != "Отдел возвратов")
        return
    CurrentTask := "F5"
    WaitText := "Ожидание особого случая"
    SetKeyDelay, 30, 20
    UpdateStatus("Особый случай: часть 1...")

    SendInput, ^n
    Sleep, 50
    SendInput, {Tab}
    Sleep, 50
    SendInput, {Enter}
    Sleep, 50

    SendInput, %F5_ClientNumber%
    Sleep, 50

    MouseClick, Left, 830, 138
    Sleep, 50

    SendInput, ^+{Left}
    Sleep, 50
    SendInput, {Backspace}
    Sleep, 50

    SendInput, %F5_Months%
    Sleep, 50

    MouseClick, Left, 235, 124
    Sleep, 50
return

; ============================================
; Ctrl + Numpad1 — по профилю
; ============================================
^Numpad1::
    if (Profile = "Дека") {
        SetKeyDelay, 30, 20
        UpdateStatus("Дека: Создать список v-склады...")

        MouseClick, Left, 58, 441
        Sleep, 3000

        MouseClick, Left, 16, 68
        Sleep, 1000

        MouseClick, Left, 719, 418
        Sleep, 50

        Clipboard := "v-склады из Елино на Лит"
        ClipWait, 1
        SendInput, ^v
        Sleep, 50

        MouseClick, Left, 931, 556
        Sleep, 50

        SendInput, {Text}м
        Sleep, 50

        SendInput, {Down}
        Sleep, 50
        SendInput, {Down}
        Sleep, 50
        SendInput, {Down}
        Sleep, 50
        SendInput, {Enter}
        Sleep, 50

        MouseClick, Left, 1200, 702
        Sleep, 50

        UpdateStatus("Дека: готово")
        Sleep, 1200
        UpdateStatus("Готов")
        return
    }

    if (Profile != "Отдел возвратов")
        return

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
    if (Profile != "Отдел возвратов")
        return
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

    Clipboard := "%Василия петушкова, 25%"
    ClipWait, 1
    SendInput, ^v
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
    if (Profile != "Отдел возвратов")
        return
    if (CurrentTask = "1") {
        UpdateStatus("Продолжение: Товар с реализации...")
        SetKeyDelay, 30, 20

        MouseClick, Left, 980, 310, 2
        Sleep, 50

        Clipboard := "Товар с реализации"
        ClipWait, 1
        SendInput, ^v
        Sleep, 50

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
    else if (CurrentTask = "F5") {
        UpdateStatus("Продолжение: Особый случай...")
        SetKeyDelay, 30, 20

        Send, #{Up}
        Sleep, 50

        MouseClick, Left, 264, 879
        Sleep, 50
        MouseClick, Left, 264, 612
        Sleep, 50

        MouseClick, Left, 173, 947
        Sleep, 50
        Send, ^+{Left}
        Sleep, 50
        Send, {Backspace}
        Sleep, 50

        if (F5_UsePercent) {
            SendInput, %F5_Percent%
            Sleep, 50
        }

        MouseClick, Left, 1157, 905
        Sleep, 50

        if (F5_UseComment) {
            Clipboard := F5_Comment
            ClipWait, 1
            SendInput, ^v
            Sleep, 50
        }

        SendInput, {Enter}
        Sleep, 50
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
    else {
        UpdateStatus("Нет активной задачи. Нажми Ctrl+Numpad1, Ctrl+Numpad4 или Ctrl+F5")
        Sleep, 1500
        UpdateStatus("Готов")
    }
return

; ============================================
; Ctrl + Numpad5 - Поиск по клиентскому
; ============================================
^Numpad5::
    if (Profile != "Отдел возвратов")
        return
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
; Ctrl + Numpad7 / 8 / 9
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

    Clipboard := "Поздний возврат"
    ClipWait, 1
    Send, ^v
    Sleep, 50

    Send, {Enter}
    Sleep, 50
    Send, {F10}
    Sleep, 800
    UpdateStatus("Готов")
}

; --- Профиль "Отдел возвратов" ---
^Numpad7::
    if (Profile = "Дека") {
        SetKeyDelay, 30, 20
        UpdateStatus("Дека: вставка кода 1...")

        MouseClick, Left, 758, 658
        Sleep, 50
        MouseClick, Left, 875, 453
        Sleep, 50
        MouseClick, Left, 1053, 660
        Sleep, 50
        MouseClick, Left, 959, 380
        Sleep, 50

        Clipboard := "]C04WjP7O8j03fMZPHPvqEA8A0r+cUP/XLX"
        ClipWait, 1
        SendInput, ^v
        Sleep, 50

        SendInput, {Enter}
        Sleep, 50

        UpdateStatus("Дека: готово")
        Sleep, 1200
        UpdateStatus("Готов")
        return
    }

    if (Profile != "Отдел возвратов")
        return
    UpdateStatus("Возврат 9")
    DoRoutine("9")
return

^Numpad8::
    if (Profile = "Дека") {
        SetKeyDelay, 30, 20
        UpdateStatus("Дека: вставка кода 2...")

        MouseClick, Left, 758, 658
        Sleep, 50
        MouseClick, Left, 875, 453
        Sleep, 50
        MouseClick, Left, 1053, 660
        Sleep, 50
        MouseClick, Left, 959, 380
        Sleep, 50

        Clipboard := "]C00Wjhz/xLVeod5LTxah1T9EodPWB/2tHx"
        ClipWait, 1
        SendInput, ^v
        Sleep, 50

        SendInput, {Enter}
        Sleep, 50

        UpdateStatus("Дека: готово")
        Sleep, 1200
        UpdateStatus("Готов")
        return
    }

    if (Profile != "Отдел возвратов")
        return
    UpdateStatus("Возврат 18")
    DoRoutine("18")
return

^Numpad9::
    if (Profile != "Отдел возвратов")
        return
    UpdateStatus("Возврат 27")
    DoRoutine("27")
return

; ============================================
; Insert - показать / скрыть оверлей
; ============================================
Insert::
    if (OverlayVisible) {
        Gui, Main:Hide
        OverlayVisible := false
    } else {
        Gui, Main:Show, NoActivate, Overlay
