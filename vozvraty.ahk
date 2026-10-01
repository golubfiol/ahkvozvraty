#NoEnv
SendMode Input
SetWorkingDir %A_ScriptDir%
CoordMode, Mouse, Screen
SetBatchLines, -1

; ============================================
; НАСТРОЙКИ АВТООБНОВЛЕНИЯ
; ============================================
global CurrentVersion := "5.5"
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

global AcceptComment    := "Товар с реализации"

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
; НАСТРОЙКИ ЧАТА
; ============================================
global Token := "y0__wgBEIydlLYDGOb8SiCZ6b6dGTDOzav5CFJ4niJUB1niLWTQwKuBYwNVFGdE"
global FolderPath := "disk:/AHK_Chat/messages"
global PinnedPath := "disk:/AHK_Chat/pinned.txt"
global UserName := A_ComputerName
global ChatOpen := false
global LastMessageKey := ""
global PinnedMessages := {}

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

    IniRead, v, %SettingsFile%, Settings, AcceptComment, %A_Space%
    if (v != "" && v != "ERROR")
        AcceptComment := v

    IniRead, v, %SettingsFile%, Settings, Profile, %A_Space%
    if (v = "Отдел возвратов" || v = "Дека")
        Profile := v
    else
        IniWrite, %Profile%, %SettingsFile%, Settings, Profile

    IniRead, savedName, %SettingsFile%, Chat, UserName, %A_Space%
    if (savedName != "" && savedName != "ERROR")
        UserName := savedName
}
else {
    IniWrite, %Profile%, %SettingsFile%, Settings, Profile
    IniWrite, %AcceptComment%, %SettingsFile%, Settings, AcceptComment
}

; ============================================
; Оверлей
; ============================================
global StatusText
global OverlayVisible := true

BuildOverlay()

; Чат — папки в облаке
CreateFolderIfNotExists("disk:/AHK_Chat")
CreateFolderIfNotExists(FolderPath)

; Чат — GUI
Gui, Chat:Destroy
Gui, Chat:+AlwaysOnTop +ToolWindow +Resize
Gui, Chat:Color, F0F0F0

Gui, Chat:Font, s11 cBlack Bold, Segoe UI
Gui, Chat:Add, Text, x15 y15 w400, === ЧАТ ===

Gui, Chat:Font, s9 cGray Norm, Segoe UI
Gui, Chat:Add, Text, x15 y40 w400, Ctrl+NumpadEnter - закрыть | Enter - отправить

Gui, Chat:Font, s10 cBlack Norm, Consolas
Gui, Chat:Add, ListBox, x15 y65 w410 h330 vChatLog +VScroll,

Gui, Chat:Font, s10 cBlack Norm, Segoe UI
Gui, Chat:Add, Edit, x15 y405 w270 h30 vChatInput Multi gChatInputChanged

Gui, Chat:Font, s10 cBlack Bold, Segoe UI
Gui, Chat:Add, Button, x290 y405 w60 h30 gSendMessageBtn, ОК
Gui, Chat:Add, Button, x355 y405 w70 h30 gAttachFileBtn, Файл

Gui, Chat:Font, s9 cBlack Norm, Segoe UI
Gui, Chat:Add, Button, x15 y445 w90 h28 gRefreshBtn, Обновить
Gui, Chat:Add, Button, x110 y445 w90 h28 gPinBtn, Закрепить
Gui, Chat:Add, Button, x205 y445 w90 h28 gSettingsBtn, Настройки
Gui, Chat:Add, Button, x300 y445 w125 h28 gChatCloseBtn, Закрыть

SetTimer, BlinkWait, 600
SetTimer, AutoCheck, 30000
SetTimer, CleanOldMessages, 3600000
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
        Gui, Main:Add, Text, x15 y%yPos% w400, 1) Ctrl + Numpad1 - Приём через счёт
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
        Gui, Main:Add, Text, x15 y%yPos% w400, 14) Ctrl + NumpadEnter - Чат
        yPos += 22
    }
    else if (Profile = "Дека") {
        Gui, Main:Add, Text, x15 y%yPos% w400, 1) Ctrl + Numpad1 - Создать список v-склады
        yPos += 22
        Gui, Main:Add, Text, x15 y%yPos% w400, 2) Ctrl + Numpad7 - Триал Виталий
        yPos += 22
        Gui, Main:Add, Text, x15 y%yPos% w400, 3) Ctrl + Numpad8 - Триал Георгий
        yPos += 22
        Gui, Main:Add, Text, x15 y%yPos% w400, 4) Ctrl + Numpad/ - Сменить профиль
        yPos += 22
        Gui, Main:Add, Text, x15 y%yPos% w400, 5) Insert - Скрыть/Показать
        yPos += 22
        Gui, Main:Add, Text, x15 y%yPos% w400, 6) Home - Перезапуск AHK
        yPos += 22
        Gui, Main:Add, Text, x15 y%yPos% w400, 7) End - Закрыть ахк
        yPos += 22
        Gui, Main:Add, Text, x15 y%yPos% w400, 8) Ctrl + NumpadEnter - Чат
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

UpdateStatus(txt) {
    GuiControl, Main:, StatusText, %txt%
}

BlinkWait:
    if (CurrentTask = "") {
        return
    }
    BlinkState := !BlinkState
    if (BlinkState) {
        txt := ">>> " . WaitText . " <<<"
        UpdateStatus(txt)
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
; Home — перезапуск
; ============================================
Home::
    TrayTip, Vozvraty, Перезапуск скрипта..., 3, 1
    Sleep, 800
    Reload
return

; ============================================
; End — закрыть скрипт
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
    Gui, ChangeNum:Add, Text, x20 y15 w320 cLime, Изменить число
    Gui, ChangeNum:Font, s9 cYellow Norm
    Gui, ChangeNum:Add, Text, x20 y45 w320, Текущие значения:
    Gui, ChangeNum:Font, s9 cWhite Norm
    Gui, ChangeNum:Add, Text, x20 y65 w320, Поиск по клиентскому: %SearchNumber%
    Gui, ChangeNum:Add, Text, x20 y85 w320, Приём через счёт: %SearchNumber1%
    Gui, ChangeNum:Add, Text, x20 y105 w320, Комментарий: %AcceptComment%
    Gui, ChangeNum:Font, s10 cWhite Bold
    Gui, ChangeNum:Add, Button, x20 y140 w150 h32 gChangeClient, Поиск
    Gui, ChangeNum:Add, Button, x180 y140 w160 h32 gChangeTovar, Приём через счёт
    Gui, ChangeNum:Add, Button, x20 y180 w320 h32 gChangeAcceptComment, Комментарий "Приём через счёт"
    Gui, ChangeNum:Add, Button, x20 y220 w320 h32 gChangeSpecial, Особый случай
    Gui, ChangeNum:Add, Button, x20 y260 w320 h28 gChangeCancel, Отмена

    Gui, ChangeNum:Show, w360 h310, Изменить число
return

ChangeAcceptComment:
    Gui, ChangeNum:Destroy
    InputBox, NewComment, Комментарий, Введи текст комментария для "Приём через счёт":, , 320, 130, , , , , %AcceptComment%
    if (ErrorLevel = 0 && NewComment != "") {
        AcceptComment := NewComment
        IniWrite, %AcceptComment%, %SettingsFile%, Settings, AcceptComment
        txt := "Сохранено: " . AcceptComment
        UpdateStatus(txt)
        Sleep, 1500
        UpdateStatus("Готов")
    }
return

ChangeClient:
    Gui, ChangeNum:Destroy
    InputBox, NewNum, Поиск по клиентскому, Введи число:, , 260, 130, , , , , %SearchNumber%
    if (ErrorLevel = 0 && NewNum != "") {
        SearchNumber := NewNum
        IniWrite, %SearchNumber%, %SettingsFile%, Settings, SearchNumber
        txt := "Сохранено (клиентский): " . SearchNumber
        UpdateStatus(txt)
        Sleep, 1500
        UpdateStatus("Готов")
    }
return

ChangeTovar:
    Gui, ChangeNum:Destroy
    InputBox, NewNum1, Приём через счёт, Введи число:, , 260, 130, , , , , %SearchNumber1%
    if (ErrorLevel = 0 && NewNum1 != "") {
        SearchNumber1 := NewNum1
        IniWrite, %SearchNumber1%, %SettingsFile%, Settings, SearchNumber1
        txt := "Сохранено (приём): " . SearchNumber1
        UpdateStatus(txt)
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
; Особый случай
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
; Ctrl + F5 — Особый случай
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

        MouseClick, Left, 52, 623
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
    WaitText := "Ожидание приём через счёт"
    SetKeyDelay, 30, 20
    UpdateStatus("Приём через счёт: часть 1...")

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
; Ctrl + Numpad4
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
; Ctrl + Numpad+
; ============================================
^NumpadAdd::
    if (Profile != "Отдел возвратов")
        return
    if (CurrentTask = "1") {
        UpdateStatus("Продолжение: Приём через счёт...")
        SetKeyDelay, 30, 20

        MouseClick, Left, 980, 310, 2
        Sleep, 50

        Clipboard := AcceptComment
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
; Ctrl + Numpad5
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
; DoRoutine — Поздний возврат
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

; ============================================
; Ctrl + Numpad7 / 8 / 9
; ============================================
^Numpad7::
    if (Profile = "Дека") {
        SetKeyDelay, 30, 20
        UpdateStatus("Дека: вставка кода 1...")

        MouseClick, Left, 758, 658
        Sleep, 300
        MouseClick, Left, 875, 453
        Sleep, 300
        MouseClick, Left, 1053, 660
        Sleep, 300
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
        Sleep, 300
        MouseClick, Left, 875, 453
        Sleep, 300
        MouseClick, Left, 1053, 660
        Sleep, 300
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
; Insert — показать/скрыть оверлей
; ============================================
Insert::
    if (OverlayVisible) {
        Gui, Main:Hide
        OverlayVisible := false
    } else {
        Gui, Main:Show, NoActivate, Overlay
        WinSet, Transparent, 128, Main
        OverlayVisible := true
    }
return

; ============================================
; ЧАТ — ОБРАБОТКА ВВОДА
; ============================================
ChatInputChanged:
    GuiControlGet, inputText,, ChatInput
    if (InStr(inputText, "`n") || InStr(inputText, "`r")) {
        cleanText := Trim(inputText, " `t`r`n")
        GuiControl,, ChatInput,
        if (cleanText != "") {
            result := SendMessage(cleanText)
            if (result) {
                TrayTip, Чат, Отправлено: %cleanText%, 3, 1
            } else {
                MsgBox, 16, Ошибка, Не удалось отправить сообщение!
            }
            SetTimer, DelayedRefresh, -2000
        }
    }
return

; ============================================
; ЧАТ — Ctrl + NumpadEnter
; ============================================
^NumpadEnter::
    if (ChatOpen) {
        Gui, Chat:Hide
        ChatOpen := false
    } else {
        PositionChatGui()
        ChatOpen := true
        RefreshChat()
        GuiControl, Chat:Focus, ChatInput
    }
return

PositionChatGui() {
    SysGet, ScreenW, 0
    SysGet, ScreenH, 1
    winW := 440
    winH := 495
    posX := ScreenW - winW - 20
    posY := 480
    if (posY + winH > ScreenH - 20)
        posY := ScreenH - winH - 20
    Gui, Chat:Show, x%posX% y%posY% w%winW% h%winH% NoActivate, Чат
}

; ============================================
; ЧАТ — КНОПКИ
; ============================================
SendMessageBtn:
    GuiControlGet, text,, ChatInput
    text := Trim(text, " `t`r`n")
    if (text = "")
        return
    GuiControl,, ChatInput,
    result := SendMessage(text)
    if (result) {
        TrayTip, Чат, Отправлено: %text%, 3, 1
    } else {
        MsgBox, 16, Ошибка, Не удалось отправить сообщение!
    }
    SetTimer, DelayedRefresh, -2000
return

AttachFileBtn:
    FileSelectFile, selectedFile, 3,, Выбери файл, Все файлы (*.*)
    if (selectedFile = "")
        return
    AttachFile(selectedFile)
    SetTimer, DelayedRefresh, -3000
return

RefreshBtn:
    RefreshChat()
return

SettingsBtn:
    InputBox, newName, Настройки, Введи своё имя:, , 300, 130, , , , , %UserName%
    if (ErrorLevel = 0 && newName != "") {
        UserName := newName
        IniWrite, %UserName%, %SettingsFile%, Chat, UserName
        MsgBox, 64, Готово, Имя сохранено: %UserName%
    }
return

PinBtn:
    MsgBox, 3, Закрепление, Что сделать?`n`nДа — закрепить последнее сообщение`nНет — показать и управлять закреплёнными`nОтмена — выход
    IfMsgBox, Yes
        PinLastMessage()
    else IfMsgBox, No
        ManagePinnedMessages()
return

PinLastMessage() {
    global PinnedPath, Token

    msgs := GetMessages(1)
    if (msgs.MaxIndex() = 0) {
        MsgBox, Нет сообщений для закрепления
        return
    }
    m := msgs[1]
    pinText := "[" . m.time . "] " . m.user . ": " . m.text

    existing := ReadPinnedFile()
    newContent := existing . pinText . "`n"

    UploadTextFile(PinnedPath, newContent)
    LoadPinned()
    MsgBox, 64, Готово, Сообщение закреплено`n`n%pinText%
}

ManagePinnedMessages() {
    LoadPinned()

    if (PinnedMessages.MaxIndex() = 0) {
        MsgBox, Закреплённых сообщений нет
        return
    }

    msg := "Закреплённые сообщения:`n`n"
    for idx, p in PinnedMessages {
        msg .= idx . ") " . p . "`n"
    }
    msg .= "`nВведи номер для открепления (0 — отмена):"

    InputBox, num, Управление закреплёнными, %msg%, , 500, 350
    if (ErrorLevel = 1 || num = "" || num = "0")
        return

    if (num < 1 || num > PinnedMessages.MaxIndex()) {
        MsgBox, Неверный номер
        return
    }

    UnpinMessage(num)
}

UnpinMessage(index) {
    global PinnedPath, Token, PinnedMessages

    newContent := ""
    for idx, p in PinnedMessages {
        if (idx = index)
            continue
        newContent .= p . "`n"
    }

    UploadTextFile(PinnedPath, newContent)
    LoadPinned()

    MsgBox, 64, Готово, Сообщение откреплено
}

ReadPinnedFile() {
    global PinnedPath, Token

    url := "https://cloud-api.yandex.net/v1/disk/resources/download?path=" . PinnedPath

    try {
        whr := ComObjCreate("WinHttp.WinHttpRequest.5.1")
        whr.Open("GET", url, false)
        whr.SetRequestHeader("Authorization", "OAuth " . Token)
        whr.Send()
        whr.WaitForResponse()
        if (whr.Status != 200)
            return ""
        resp := whr.ResponseText
    } catch {
        return ""
    }

    q := Chr(34)
    hrefPos := InStr(resp, q . "href" . q . ":" . q)
    if (!hrefPos)
        return ""
    hrefPos += 8
    endPos := hrefPos
    while (endPos <= StrLen(resp)) {
        ch := SubStr(resp, endPos, 1)
        if (ch = q)
            break
        endPos++
    }
    fileUrl := SubStr(resp, hrefPos, endPos - hrefPos)

    tempFile := A_Temp . "\pin_" . A_TickCount . ".txt"
    FileDelete, %tempFile%
    UrlDownloadToFile, %fileUrl%, %tempFile%

    text := ""
    if (ErrorLevel = 0 && FileExist(tempFile)) {
        streamIn := ComObjCreate("ADODB.Stream")
        streamIn.Type := 2
        streamIn.Charset := "utf-8"
        streamIn.Open()
        streamIn.LoadFromFile(tempFile)
        text := streamIn.ReadText()
        streamIn.Close()
    }
    FileDelete, %tempFile%
    return text
}

LoadPinned() {
    global PinnedMessages
    PinnedMessages := {}
    content := ReadPinnedFile()
    if (content = "")
        return

    Loop, Parse, content, `n, `r
    {
        line := Trim(A_LoopField, " `t`r`n")
        if (line != "")
            PinnedMessages.Push(line)
    }
}

ChatCloseBtn:
    Gui, Chat:Hide
    ChatOpen := false
return

DelayedRefresh:
    RefreshChat()
return

; ============================================
; ЧАТ — ОБНОВИТЬ ЛЕНТУ
; ============================================
RefreshChat() {
    global LastMessageKey, PinnedMessages

    LoadPinned()

    msgs := GetMessages(5)

    allLines := []

    if (PinnedMessages.MaxIndex() > 0) {
        allLines.Push("=== ЗАКРЕПЛЁННЫЕ ===")
        for idx, p in PinnedMessages {
            allLines.Push("* " . p)
        }
        allLines.Push("===================")
        allLines.Push("")
    }

    total := msgs.MaxIndex()
    Loop, %total%
    {
        m := msgs[A_Index]
        mTime := m.time
        mUser := m.user
        mText := m.text
        allLines.Push("[" . mTime . "] " . mUser)
        allLines.Push(mText)
        allLines.Push("------------------------------")
    }
    if (allLines.MaxIndex() = 0)
        allLines.Push("Сообщений пока нет")

    listData := ""
    for idx, line in allLines {
        listData .= line . "|"
    }

    ControlGet, hLB, Hwnd,, ListBox1, Чат
    if (hLB)
        SendMessage, 0x0184, 0, 0, , ahk_id %hLB%

    GuiControl, Chat:, ChatLog, %listData%

    if (msgs.MaxIndex() > 0) {
        newest := msgs[1]
        newestKey := newest.time . "_" . newest.user . "_" . newest.text

        if (LastMessageKey = "") {
            LastMessageKey := newestKey
        } else if (LastMessageKey != newestKey) {
            SoundPlay, *-1
            ShowPopup(newest.user, newest.text)
            LastMessageKey := newestKey
        }
    }
}

; ============================================
; ЧАТ — УВЕДОМЛЕНИЕ
; ============================================
ShowPopup(user, text) {
    short := SubStr(text, 1, 100)
    msg := user . " пишет:`n`n" . short

    SysGet, ScreenW, 0
    SysGet, ScreenH, 1
    popW := 350
    popH := 100
    popX := ScreenW - popW - 30
    popY := ScreenH - popH - 60

    SplashTextOn, %popW%, %popH%, Новое сообщение, %msg%
    WinMove, Новое сообщение,, %popX%, %popY%
    SetTimer, ClosePopup, -5000
}

ClosePopup:
    SplashTextOff
return

; ============================================
; ЧАТ — ТАЙМЕРЫ
; ============================================
AutoCheck:
    if (ChatOpen)
        RefreshChat()
return

CleanOldMessages:
    DeleteOldMessages(30)
return

; ============================================
; ЧАТ — ФУНКЦИИ ОТПРАВКИ
; ============================================
CreateFolderIfNotExists(path) {
    global Token
    url := "https://cloud-api.yandex.net/v1/disk/resources?path=" . path
    try {
        whr := ComObjCreate("WinHttp.WinHttpRequest.5.1")
        whr.Open("PUT", url, false)
        whr.SetRequestHeader("Authorization", "OAuth " . Token)
        whr.Send()
        whr.WaitForResponse()
    }
}

SendMessage(text) {
    global Token, FolderPath, UserName
    FormatTime, timestamp,, yyyy-MM-dd_HH-mm-ss
    fileName := timestamp . "_" . UserName . ".txt"
    fullPath := FolderPath . "/" . fileName
    result := UploadTextFile(fullPath, text)
    return result
}

AttachFile(filePath) {
    global Token, FolderPath, UserName

    SplitPath, filePath, fileName
    FileGetSize, fileSize, %filePath%
    if (fileSize > 104857600) {
        MsgBox, Файл больше 100 МБ
        return
    }

    FormatTime, timestamp,, yyyy-MM-dd_HH-mm-ss
    remoteName := timestamp . "_FILE_" . UserName . "_" . fileName
    remotePath := FolderPath . "/" . remoteName

    if (!UploadBinaryFile(remotePath, filePath)) {
        MsgBox, Ошибка загрузки файла
        return
    }

    publicUrl := GetPublicUrl(remotePath)

    msgText := "[Файл] " . fileName . " — " . publicUrl
    SendMessage(msgText)
    MsgBox, 64, Готово, Файл загружен и отправлен
}

UploadTextFile(remotePath, text) {
    global Token

    tempFile := A_Temp . "\upl_" . A_TickCount . ".txt"
    FileDelete, %tempFile%

    stream := ComObjCreate("ADODB.Stream")
    stream.Type := 2
    stream.Charset := "utf-8"
    stream.Open()
    stream.WriteText(text)
    stream.SaveToFile(tempFile, 2)
    stream.Close()

    if (!FileExist(tempFile)) {
        MsgBox, Ошибка: временный файл не создан
        return false
    }

    result := UploadBinaryFile(remotePath, tempFile)
    FileDelete, %tempFile%
    return result
}

UploadBinaryFile(remotePath, localFile) {
    global Token

    encodedPath := StrReplace(remotePath, ":", "%3A")
    url := "https://cloud-api.yandex.net/v1/disk/resources/upload?path=" . encodedPath . "&overwrite=true"

    try {
        whr := ComObjCreate("WinHttp.WinHttpRequest.5.1")
        whr.Open("GET", url, false)
        whr.SetRequestHeader("Authorization", "OAuth " . Token)
        whr.Send()
        whr.WaitForResponse()
        resp := whr.ResponseText
        statusURL := whr.Status
    } catch {
        MsgBox, Ошибка HTTP (получение URL): %e%
        return false
    }

    if (statusURL != 200) {
        MsgBox, Ошибка получения URL.`nКод: %statusURL%`n`n%resp%
        return false
    }

    q := Chr(34)
    hrefPos := InStr(resp, q . "href" . q . ":" . q)
    if (!hrefPos) {
        MsgBox, Не найден href в ответе:`n%resp%
        return false
    }
    hrefPos += 8
    endPos := hrefPos
    while (endPos <= StrLen(resp)) {
        ch := SubStr(resp, endPos, 1)
        if (ch = "\") {
            endPos += 2
            continue
        }
        if (ch = q)
            break
        endPos++
    }
    uploadUrl := SubStr(resp, hrefPos, endPos - hrefPos)

    streamIn := ComObjCreate("ADODB.Stream")
    streamIn.Type := 1
    streamIn.Open()
    streamIn.LoadFromFile(localFile)
    binData := streamIn.Read()
    streamIn.Close()

    try {
        whr2 := ComObjCreate("WinHttp.WinHttpRequest.5.1")
        whr2.Open("PUT", uploadUrl, false)
        whr2.SetRequestHeader("Content-Type", "application/octet-stream")
        whr2.Send(binData)
        whr2.WaitForResponse()
        statusUpload := whr2.Status
        respUpload := whr2.ResponseText
    } catch {
        MsgBox, Ошибка HTTP (загрузка): %e%
        return false
    }

    if (statusUpload = 201 || statusUpload = 200 || statusUpload = 204)
        return true

    MsgBox, Ошибка загрузки файла.`nКод: %statusUpload%`n`n%respUpload%
    return false
}

GetPublicUrl(remotePath) {
    global Token

    encodedPath := StrReplace(remotePath, ":", "%3A")
    urlPub := "https://cloud-api.yandex.net/v1/disk/resources/publish?path=" . encodedPath
    try {
        whr := ComObjCreate("WinHttp.WinHttpRequest.5.1")
        whr.Open("PUT", urlPub, false)
        whr.SetRequestHeader("Authorization", "OAuth " . Token)
        whr.Send()
        whr.WaitForResponse()
    }

    urlInfo := "https://cloud-api.yandex.net/v1/disk/resources?path=" . encodedPath . "&fields=public_url"
    try {
        whr2 := ComObjCreate("WinHttp.WinHttpRequest.5.1")
        whr2.Open("GET", urlInfo, false)
        whr2.SetRequestHeader("Authorization", "OAuth " . Token)
        whr2.Send()
        whr2.WaitForResponse()
        resp := whr2.ResponseText
    } catch {
        return ""
    }

    q := Chr(34)
    pos := InStr(resp, q . "public_url" . q . ":" . q)
    if (!pos)
        return ""
    pos += 14
    endPos := pos
    while (endPos <= StrLen(resp)) {
        ch := SubStr(resp, endPos, 1)
        if (ch = q)
            break
        endPos++
    }
    return SubStr(resp, pos, endPos - pos)
}

; ============================================
; ЧАТ — ЧТЕНИЕ СООБЩЕНИЙ
; ============================================
GetMessages(limit) {
    global Token, FolderPath

    url := "https://cloud-api.yandex.net/v1/disk/resources?path=" . FolderPath . "&limit=1000"

    try {
        whr := ComObjCreate("WinHttp.WinHttpRequest.5.1")
        whr.Open("GET", url, false)
        whr.SetRequestHeader("Authorization", "OAuth " . Token)
        whr.Send()
        whr.WaitForResponse()
        resp := whr.ResponseText
    } catch {
        return []
    }

    itemsStart := InStr(resp, Chr(34) . "items" . Chr(34) . ":[")
    if (!itemsStart)
        return []

    pos := itemsStart + 9
    respLen := StrLen(resp)

    files := []
    Loop {
        while (pos <= respLen && SubStr(resp, pos, 1) != "{")
            pos++
        if (pos > respLen)
            break

        startObj := pos
        depth := 0

        while (pos <= respLen) {
            ch := SubStr(resp, pos, 1)
            if (ch = "{")
                depth++
            else if (ch = "}") {
                depth--
                if (depth = 0) {
                    pos++
                    break
                }
            } else if (ch = "\") {
                pos++
            }
            pos++
        }

        objStr := SubStr(resp, startObj, pos - startObj)

        nameVal := ExtractJsonField(objStr, "name")
        typeVal := ExtractJsonField(objStr, "type")
        fileVal := ExtractJsonField(objStr, "file")

        nameVal := Trim(nameVal, " `t`r`n")
        typeVal := Trim(typeVal, " `t`r`n")
        fileVal := Trim(fileVal, " `t`r`n")

        if (nameVal = "" || typeVal != "file" || fileVal = "")
            continue

        files.Push({"name": nameVal, "url": fileVal})
    }

    sorted := SortArrayByKey(files, "name")

    result := []
    total := sorted.MaxIndex()
    startIdx := total - limit + 1
    if (startIdx < 1)
        startIdx := 1

    Loop, %total%
    {
        idx := total - A_Index + 1
        if (idx < startIdx)
            break

        f := sorted[idx]
        nameLen := StrLen(f.name)
        if (nameLen < 4)
            continue

        ext := SubStr(f.name, nameLen - 3, 4)
        isTxt := (ext = ".txt")

        fileNameNoExt := SubStr(f.name, 1, nameLen - 4)
        parts := StrSplit(fileNameNoExt, "_")
        if (parts.MaxIndex() < 3)
            continue

        datePart := Trim(parts[1], " `t`r`n")
        timePart := Trim(parts[2], " `t`r`n")

        userPart := Trim(parts[3], " `t`r`n")
        if (userPart = "FILE" && parts.MaxIndex() >= 4)
            userPart := Trim(parts[4], " `t`r`n")

        timeStr := datePart . " " . StrReplace(timePart, "-", ":")

        text := ""

        if (isTxt) {
            tempFile := A_Temp . "\dl_" . A_TickCount . ".txt"
            FileDelete, %tempFile%
            UrlDownloadToFile, % f.url, %tempFile%

            if (ErrorLevel = 0 && FileExist(tempFile)) {
                streamIn := ComObjCreate("ADODB.Stream")
                streamIn.Type := 2
                streamIn.Charset := "utf-8"
                streamIn.Open()
                streamIn.LoadFromFile(tempFile)
                text := streamIn.ReadText()
                streamIn.Close()
            }
            FileDelete, %tempFile%
        } else {
            text := "[Файл] " . f.name
        }

        result.Push({"time": timeStr, "user": userPart, "text": text})
    }

    return result
}

; Пузырьковая сортировка массива объектов по ключу
SortArrayByKey(arr, key) {
    n := arr.MaxIndex()
    if (n = "" || n < 2)
        return arr

    Loop, %n% {
        i := A_Index
        Loop, % n - i {
            j := A_Index
            if (arr[j][key] > arr[j+1][key]) {
                temp := arr[j]
                arr[j] := arr[j+1]
                arr[j+1] := temp
            }
        }
    }
    return arr
}

ExtractJsonField(objStr, fieldName) {
    q := Chr(34)
    needle := q . fieldName . q . ":" . q
    pos := InStr(objStr, needle)
    if (!pos)
        return ""

    pos += StrLen(needle)
    endPos := pos
    len := StrLen(objStr)
    while (endPos <= len) {
        ch := SubStr(objStr, endPos, 1)
        if (ch = "\") {
            endPos += 2
            continue
        }
        if (ch = q)
            break
        endPos++
    }

    return SubStr(objStr, pos, endPos - pos)
}

; ============================================
; ЧАТ — УДАЛЕНИЕ СТАРЫХ
; ============================================
DeleteOldMessages(daysOld) {
    global Token, FolderPath

    FormatTime, cutoff,, yyyy-MM-dd
    EnvAdd, cutoff, -%daysOld%, Days
    cutoff .= "_00-00-00"

    url := "https://cloud-api.yandex.net/v1/disk/resources?path=" . FolderPath . "&limit=1000"

    try {
        whr := ComObjCreate("WinHttp.WinHttpRequest.5.1")
        whr.Open("GET", url, false)
        whr.SetRequestHeader("Authorization", "OAuth " . Token)
        whr.Send()
        whr.WaitForResponse()
        resp := whr.ResponseText
    } catch {
        return
    }

    pos := 1
    while (pos := RegExMatch(resp, """name"":""(.*?)""", m, pos)) {
        name := m1
        if (SubStr(name, -4) = ".txt" || InStr(name, "_FILE_")) {
            fileDate := SubStr(name, 1, 19)
            if (fileDate < cutoff) {
                delPath := FolderPath . "/" . name
                encodedDel := StrReplace(delPath, ":", "%3A")
                delUrl := "https://cloud-api.yandex.net/v1/disk/resources?path=" . encodedDel . "&permanently=true"

                whrDel := ComObjCreate("WinHttp.WinHttpRequest.5.1")
                whrDel.Open("DELETE", delUrl, false)
                whrDel.SetRequestHeader("Authorization", "OAuth " . Token)
                whrDel.Send()
                whrDel.WaitForResponse()
            }
        }
        pos += StrLen(m)
    }
}