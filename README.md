# Astral v4.77

[Скачать Lua](https://github.com/anastasia9338338-alt/-/raw/refs/heads/codex/astral-v4.77-blobman-defense/astral.lua?download=1) · [Скачать ZIP с astral.lua](https://github.com/anastasia9338338-alt/-/raw/refs/heads/codex/astral-v4.77-blobman-defense/astral.zip?download=1)

Сборка основана на прикреплённом пользователем самостоятельном Lua-файле. Перед запуском выгрузите прежний Astral через Settings → Unload astral.

- Defense → Blobman: Anti Blobman, Anti Blobman Aura, Remove Blobman Arms и Banana Aura Blobman. Аура запрашивает ragdoll водителя; банановая аура ест настоящий банан и вращает его корку внутри Blobman. Есть радиус и настройки вращения.
- Anti Explore объединяет защиту от банана, снежка и взрыва. Вызов удаления ног из прежнего Anti Banana убран; старые дополнительные варианты заблокированы.
- Захват для Blobman Kick проверяет настоящий ответ руки перед удержанием, не требует FirePlayerPart и сохраняет RootAttachment на месте. Одна рука выполняет одну операцию.
- Меню выбора и настроек получили непрозрачный контрастный фон. Исправлены сохранение цветов темы и конечная точка градиента выбора цвета.
- Shuriken Transparency переименовано в Item Transparency.

Удаление рук действует на своём клиенте и восстанавливается при отключении. Сила отбрасывания банановой коркой, сброс водителя и результат кика зависят от сервера и игровой физики; живой Roblox здесь не проверялся.

Проверка: `python tools/verify.py --luau-dir /path/to/luau/tools --analysis-dir /path/to/logs`. Проверены 84 исполняемых модуля, встроенный исходник, соответствие ZIP, регрессионные сценарии и 100 новых изолированных проверок. Анализатор также выдаёт предупреждения об отсутствующих Roblox/executor globals и пределах вывода типов; они просмотрены и не выдаются за чистую проверку типов.
