# Vozvraty

Порт AHK-скрипта `vozvraty.ahk` на C# (.NET 8, WinForms).

## Сборка
Нужен .NET 8 SDK (только на машине, где собираешь):

    dotnet publish -c Release -o publish

Результат: `publish\Vozvraty.exe` — один файл, .NET на рабочем ПК ставить не нужно.

## Выпуск обновления
1. Поменяй `<Version>` в `Vozvraty.csproj` (например, 8.0.1).
2. Собери exe.
3. На GitHub создай Release с тегом `v8.0.1` и приложи файл `Vozvraty.exe` (имя именно такое).
Программа при запуске (и из меню в трее) сама найдёт релиз, скачает, заменит себя и перезапустится.

## Где что
- `Settings.cs` — настройки (`%AppData%\Vozvraty\settings.json`) и ВСЕ экранные координаты (класс `Pt`).
- `Actions.cs` — сценарии хоткеев.
- `Input.cs` — эмуляция клавиш/мыши/буфера.
- `Updater.cs` — автообновление через GitHub Releases.
