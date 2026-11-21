# Зоо-Бросок — Unity WebGL

Браузерный 3D-симулятор в жанре «брось еду — поймай животное»: тренируй силу броска, кидай еду по дорожке через шесть биомов, лови случайных животных семи редкостей, сажай их в загон ради пассивного дохода и покупай еду, тренажёры и улучшения.

Название, модели, интерфейс, звуки и музыка собственные. Все модели собираются кодом из примитивов, звуки и музыка синтезируются при запуске, иконки рисуются процедурно. Шрифты Russo One и PT Sans распространяются по лицензии SIL OFL, файлы лицензий лежат рядом со шрифтами.

## Быстрый старт

1. Установи **Unity 6 LTS** (6000.0.x) с модулем **WebGL Build Support**.
2. Подключи проект одним из двух способов.
   - **Рекомендуемый.** В Unity Hub создай новый проект из шаблона **Universal 3D** и скопируй в него папки `Assets/ZooThrow` и `Assets/WebGLTemplates` отсюда.
   - **Напрямую.** Unity Hub → Add → Add project from disk → выбери папку `ZooThrow` и версию 6000.0.x. Недостающие ProjectSettings Unity создаст сам, пакеты возьмёт из `Packages/manifest.json`.
3. После первой компиляции запустится автонастройка. Её можно запустить и вручную: меню **ZooThrow → 1. Настроить проект**. Что она делает:
   - импортирует TMP Essential Resources;
   - создаёт и назначает URP Asset (`Assets/ZooThrow/Settings`), если у проекта его нет;
   - создаёт кириллические TMP-шрифты в `Assets/ZooThrow/Resources/Fonts`;
   - создаёт все данные как ScriptableObject в `Assets/ZooThrow/ScriptableObjects` плюс корневую базу `Resources/ZooThrowDatabase`;
   - создаёт сцену `Assets/ZooThrow/Scenes/ZooThrow.unity` и ставит её первой в Build Settings;
   - настраивает WebGL: Brotli со встроенной распаковкой, кэш данных, свой шаблон загрузки, Linear-цвет.
4. Открой сцену `ZooThrow` и нажми **Play**.

Если TMP Essentials не импортировались автоматически: **Window → TextMeshPro → Import TMP Essential Resources**, затем снова **ZooThrow → 1. Настроить проект**.

## Сборка WebGL

- Из редактора: **ZooThrow → 3. Собрать WebGL**. Результат появится в `Builds/WebGL`.
- Из командной строки:
  ```
  Unity -batchmode -quit -projectPath <путь>/ZooThrow -buildTarget WebGL -executeMethod ZooThrow.EditorTools.ZooThrowSetup.BuildWebGLBatch -logFile build.log
  ```
  Код выхода: 0 — успех, 1 — сборка не удалась, 2 — исключение.
- Локальный запуск: `cd Builds/WebGL && python -m http.server 8080`, затем открой `http://localhost:8080`. Открывать `index.html` двойным кликом нельзя: браузер блокирует загрузку с `file://`. Встроенная распаковка (decompression fallback) позволяет обойтись без настройки заголовков Brotli на сервере. На своём хостинге лучше отдавать `.br`-файлы с `Content-Encoding: br`.

## Управление

| Клавиша | Действие |
|---|---|
| W A S D | движение, Shift — бег |
| Мышь | вращение камеры (после клика по игре курсор захватывается), колесо — зум |
| Пробел | прыжок |
| E | взаимодействие: площадка броска, магазины, турник, загон, коллекция |
| F / кнопка «БРОСИТЬ» | бросок; не на площадке — сначала перенос на неё |
| ЛКМ / Пробел / F | остановить шкалу точности |
| Q / R | предыдущая / следующая еда |
| Tab, B, U, C | Животные, Магазин, Улучшения, Коллекция |
| Esc | меню и освобождение курсора; во время прицеливания — отмена |
| Alt (удерживать) | временно освободить курсор |

## Игровой цикл

Тренировка на турнике → бросок с мини-игрой точности → полёт еды по баллистической дуге за камерой → приземление в биоме → случайное животное (редкость зависит от биома, еды и удачи) → загон → пассивный доход → покупки → дальше бросок → новый биом.

- **Дальность** = база + сила + бонус еды + бонус точности. Бонус точности — это (множитель − 1) × (база + сила + еда), поэтому у слабого броска он отрицательный. Оценки: «Слабый», «Хороший», «Отличный», «PERFECT THROW!».
- **Биомы**: Лес 0–60 м, Саванна 60–140, Пустыня 140–240, Джунгли 240–360, Океан 360–500, Горы 500–760. Биом открывается, когда еда впервые долетает до его начала.
- **37 животных**, редкости Common … Secret со своими цветами, весами и множителями дохода. Мутации «Золотой» ×2, «Радужный» ×3 и «Гигантский» ×1.5 отключаются флагом в `BalanceSettings`.
- **Загон**: 4 места на старте, до 12 через улучшения. Есть авто-расстановка лучших, замена самого слабого и продажа.
- **Офлайн-доход**: 50% дохода, по умолчанию не больше 2 часов (улучшается). Если вкладка браузера свёрнута и кадры не идут, этот промежуток оплачивается так же.
- **Сохранение**: JSON в PlayerPrefs, в WebGL это IndexedDB браузера. Есть контрольная сумма, резервная копия, починка повреждённых полей и сброс прогресса с двойным подтверждением.

## Настройка баланса

Все числа лежат в ScriptableObject в `Assets/ZooThrow/ScriptableObjects`: `BalanceSettings`, редкости, биомы, животные, еда, тренажёры, улучшения. После автонастройки правь их в инспекторе. Код менять не нужно.

**ZooThrow → Пересоздать данные** возвращает значения по умолчанию из `DefaultContent.cs` и стирает ручные правки. ID животных и еды записаны в сохранения, поэтому у существующих записей их не меняй.

## Архитектура

```
Assets/ZooThrow/
  Scripts/
    Core/         GameBootstrap (точка входа), GameManager (сервис-локатор), GameInput (старый + новый Input System), GameEvents, SettingsApplier, NumberFormat
    Data/         ScriptableObject-типы, GameDatabase, DefaultContent (стартовый контент и баланс)
    Player/       PlayerController (CharacterController), PlayerAvatar (процедурные анимации), InteractionSystem
    Camera/       ThirdPersonCamera (орбита с коллизией, прицел, слежение за едой, показ награды)
    Throwing/     ThrowController, ThrowMath + ThrowMeter (чистая логика), FoodProjectile (пул), FoodModelFactory
    Animals/      AnimalRoller (чистая логика выпадений), AnimalInventory, AnimalPen, PenView, AnimalActor, AnimalModelFactory
    Economy/      EconomyManager, UpgradeManager, PassiveIncomeManager
    Training/     TrainingManager, Progression
    Shops/        FoodShop, TrainerShop
    World/        WorldBuilder, DecorFactory, TrainerModelFactory, BiomeManager, Station, WorldLayout, TrainingView
    Visuals/      MeshBuilder (vertex-color low-poly), MaterialLibrary, VfxManager (пулы частиц), PortraitRenderer (3D-портреты для UI)
    Audio/        SoundSynth (процедурные звуки и музыка), SoundManager
    UI/           UIManager, HudView, ThrowHud, RewardView, окна (Животные, Магазин, Улучшения, Коллекция, Меню), фабрики виджетов
    SaveSystem/   SaveData, SaveManager, SaveValidator
  Editor/         ZooThrowSetup — автонастройка и сборка
  Resources/      Shaders (ToonLit, Glow, Sky для URP), Fonts и ZooThrowDatabase (создаются автонастройкой)
  Fonts/          TTF + лицензии OFL
Assets/WebGLTemplates/ZooThrow  — страница загрузки
Tools~/verify   — проверки вне Unity (Unity эту папку не импортирует)
Docs~/previews  — превью моделей и иконок, отрендеренные тем же кодом генерации
```

Сцена содержит один объект с `GameBootstrap`, всё остальное создаётся кодом в фиксированном порядке, поэтому в проекте нет ручных ссылок в сценах. Статическая геометрия склеивается в крупные vertex-color меши, декор режется на чанки по 60 м для отсечения. Еда, эффекты и всплывающие тексты переиспользуются из пулов. Сетевых запросов и потоков нет.

## Статус проверки

| Что | Результат |
|---|---|
| Компиляция всех runtime-скриптов против референсных сборок UnityEngine 2021.1 + UGUI + TMP 3.0.9 (из исходников), с `ENABLE_INPUT_SYSTEM` и без | собирается, 0 ошибок |
| Компиляция Editor-скрипта против UnityEditor 2021.1 | собирается, 0 ошибок |
| Логика и баланс (`Tools~/verify/sim`) | все проверки пройдены. Бот получает первое животное с 1-го броска, первую покупку делает на 1–2 минуте, Саванну открывает на 4–6 минуте, Горы — примерно через 50–65 минут |
| Модели и иконки (`Tools~/verify/vis`) | отрендерены тем же кодом, превью лежат в `Docs~/previews` |
| Запуск в Unity Editor, компиляция шейдеров URP, WebGL-сборка, работа в Chrome/Edge, FPS | **не проверялось**: в среде разработки нет Unity Editor |

API Unity 6 (URP 17, TMP из ugui 2.0, Input System) проверены только по сигнатурам, а пакеты Input System и URP — через заглушки. Если в Unity 6 вылезет ошибка компиляции или шейдера, её точный текст из Console почти наверняка укажет на одну конкретную строку.
