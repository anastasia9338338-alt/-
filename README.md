# Astral v4.78

[Скачать Lua](https://github.com/anastasia9338338-alt/-/raw/refs/heads/codex/astral-v4.78-restore-glass/astral.lua?download=1) · [Скачать ZIP с astral.lua](https://github.com/anastasia9338338-alt/-/raw/refs/heads/codex/astral-v4.78-restore-glass/astral.zip?download=1)

Восстановлено оформление v4.76 из коммита e99250a77c14888c380ced88d12e11f66bd396e0: прозрачный серый GUI, прежние иконки, прозрачный серый ватермарк и прежние настройки ESP. Палитра, рендерер, анимация окна и ватермарк взяты из той версии без изменений.

Добавленные в v4.77 контроллеры BlobmanDefense, BlobmanKick, BlobmanAura и AntiExplore сохранены без изменений. Сохранены их настройки и новые функции; старые разрушающие ноги варианты Anti Banana остаются заблокированы.

Перед запуском выгрузите предыдущий Astral через Settings → Unload astral.

Проверено: компиляция 84 исполняемых модулей и встроенного кода, совпадение ZIP, исходные регрессионные сценарии, 90 сценарных проверок новых контроллеров и 195 проверок GUI с оригинальным каталогом иконок. Проверяются цвета и прозрачность после применения темы и открытия/закрытия меню. Эти проверки выполняются в имитации движка; живой Roblox здесь не запускался.

`python tools/verify.py --luau-dir /path/to/luau/tools --analysis-dir /path/to/logs`
