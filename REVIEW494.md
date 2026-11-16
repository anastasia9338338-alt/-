# Review v4.94

Основной маршрут KickLoop заменён на source root contacts у подготовленной вращающейся палетки; предыдущий experimental sweep и его pulse settings больше не являются основным киком. Проверены Main callers, оба source режима, settings callbacks и отсутствие старого StableHoldBeforeRefresh в рабочем context.

Изменённые executable modules: Main, KickLoop, PalletRagdoll, Resonance29Ragdoll; добавлен PalletSupply. Последний объединяет Native/Warm создание и отправляет один RPC, отслеживает partial model и неизвестный/поздний результат, освобождает общий Spawning flag независимо от отменённого Get. Отдельно проверены поздняя доставка после смены inventory/plot folder и nil-returning RPC после unload. Неполная модель больше не уничтожается с новым spawn при каждом short part timeout.

Для native profile проверены: источник angular velocity/size/lift, MaxTorque, отдельные owned constraints, удаление conflicting profile при one-shot handoff, сохранение исходной Size/CanQuery/Massless; receiver CanTouch и contact end при остановке/respawn/unload. Локальный PartOwner, исчезающий после захвата цели, не считается основанием для повторного создания палетки. Источник Ragdolled остаётся read-only; native API calls не увеличивают confirmed server hits.

Удерживающий BP соответствует source D=100, лишний gyro не создаётся в source modes; Main стабилизирует скорости только physically owned частей. Родные joints и масса персонажа не меняются. Одиночная цель остаётся над текущими X/Z игрока, selection/protection/root identity отменяют старую сессию. Faster/Normal event order, исходное ограничение частоты и управляемый полный цикл Loop MS сохранены.

Проверена точная конечная сборка командой:

```sh
python tools/verify.py --luau-dir /workspace/work/luau-bin --analysis-dir /workspace/work/fix494/analysis
```

Результат: 90 executable modules, embedded gameplay, 35 controller bindings, совпадение Lua внутри ZIP; проверка завершилась с exit code 0. Новые harnesses: 3521 single-pallet lifecycle, 732 source spin/contact/partial-model и 18 Main route/stabilization checks. Source Faster/Normal regression: 3357 assertions; Loop MS: 24527. Это fake engine/CLI проверки.

Analyzer logs просмотрены для изменённых модулей и всего bundle. После нормализации строк/внутренних blocked type IDs Main, KickLoop, PalletRagdoll и Resonance29Ragdoll не добавляют non-ambient diagnostics относительно v4.93. PalletSupply: UnknownType Instance из отсутствующих Roblox definitions и два benign ImplicitReturn (ожидаемый nil в Find/Get). Необъявленных обфусцированных locals, SyntaxError и UninitializedLocal нет. Полного Roblox typecheck не заявляется.

Байтово сохранены по отношению к v4.93: Library, Watermark; прочие runtime modules, кроме перечисленных выше, также неизменны. Тема, watermark, иконки, store callbacks и PCLD не перерабатывались.

Live Roblox/executor отсутствует: успешность/скорость серверного кика, принятие контактов и immunity к чужому grab не доказаны. Подготовленная игрушка остаётся реплицируемой; она вынесена за обычную досягаемость, серверная невидимость/защита не имитируется LocalTransparencyModifier. Неизвестный spawn outcome ожидается без автоматического дублирования; это сознательное ограничение для предотвращения спама.

Lua SHA-256: `a1d10368be04b9328f91da351f823794991161f118096e6377b8fe7c2662a762`
ZIP SHA-256: `f6ecd0c2e6eabf22a3375c0dd71e21c5e5c5f08c52ff5840708b1edbf7de00f0`
