# GAPer Forever

GAPerGuide 0.4.1 для WoW: Forever beta. Исходный игровой код перенесён без изменений.

## Установка
Скачайте GAPerUpdater.zip из [последнего релиза](https://github.com/gaperforever/GAPer-Forever/releases/latest), распакуйте, проверьте wow_path в config.json и запустите Update GAPer.bat при закрытой игре.
Для Program Files могут потребоваться права администратора.
Второй BAT после успешной проверки открывает Battle.net.
Обновляется только Interface/AddOns/GAPerGuide. Настройки WTF сохраняются.
Резервные копии находятся в GAPerBackups внутри папки WoW.

## Выпуск
Измените версию в GAPerGuide/GAPerGuide.toc, обновите CHANGELOG.md и отправьте тег vX.Y.Z.
GitHub Actions создаёт Release с GAPerGuide.zip, GAPerUpdater.zip и SHA256SUMS.txt.
Можно запустить workflow вручную с версией X.Y.Z.
Локальная сборка: powershell -File scripts/build.ps1 -Version 0.4.1
