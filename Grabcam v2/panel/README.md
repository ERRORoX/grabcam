# Панель Grabcam (модульная)

Автор: **ERRORoX**

## Структура модулей

Каждая карточка и каждая функция вынесены в отдельные модули.

```
panel/
├── js/
│   ├── tool-grabcam.js          # Точка входа: только initPanel и сборка
│   ├── grabcam-layout.config.js # Макет карточек (порядок, сетка)
│   └── modules/
│       ├── config.js            # API, лимиты, интервалы опроса
│       ├── state.js             # Общее состояние (sessionStartTime, last*)
│       ├── utils.js             # Утилиты: форматирование, рендер, карта
│       ├── layout.js            # getLayout, buildPanelHTML
│       ├── widgets/             # HTML разметка каждого виджета
│       │   ├── index.js         # getWidgetHTMLMap
│       │   ├── control.js … summary-text.js
│       └── features/           # Логика по одной карточке/функции
│           ├── index.js         # Сводный экспорт
│           ├── session.js       # Сводка сессии (длительность, цели, IP)
│           ├── control.js       # Запуск/остановка, опции, ссылка
│           ├── link.js          # Копирование, экспорт
│           ├── map.js           # Карта (показать точку, очистить)
│           ├── photos.js        # Загрузка фото
│           ├── locations.js     # Местоположения + «На карте»
│           ├── forms.js         # Захваты форм
│           ├── screen.js        # Захват экрана
│           ├── audio.js         # Аудио
│           └── summary.js       # Текстовая сводка
└── css/
    ├── tool-grabcam.css         # Импорты (точка входа)
    ├── base.css, shared.css
    └── widgets/                # Один файл = одна карточка
```

- **config** — константы. **state** — общее состояние панели.
- **utils** — чистые функции. **layout** — макет и сборка HTML.
- **widgets/** — только разметка (HTML). **features/** — логика и опрос API по карточкам.
- **css/widgets/** — стили по одной карточке (см. css/README.md).
