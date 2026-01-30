# Image Compressor (converter-web)

PWA для сжатия и конвертации изображений в браузере. Работает офлайн после первой загрузки.

- **Версия:** 1.0.0  
- **Платформа:** Flutter Web

## Запуск локально

Запусти сервер из **корня проекта**:

```bash
cd /path/to/converter-web
python3 -m http.server 8080
```

Открой в браузере: **http://localhost:8080/**

## Сборка из исходников

Исходный код Flutter: `lib/main.dart`, `lib/home_page.dart`. Шаблон веб-оболочки: `web/index.html`.

```bash
flutter pub get
flutter build web
```

Результат сборки — в `build/web/`. Чтобы обновить сайт в корне проекта, скопируй содержимое `build/web/` в корень.

Разработка с горячей перезагрузкой:

```bash
flutter pub get
flutter run -d chrome
```

## Структура проекта

| Путь | Назначение |
|------|------------|
| `index.html` | Точка входа, экран загрузки |
| `main.dart.js` | Скомпилированное приложение |
| `flutter.js`, `flutter_bootstrap.js` | Загрузчик Flutter |
| `canvaskit/` | Движок рендеринга (локальный) |
| `manifest.json` | PWA: название, иконки, тема |
| `flutter_service_worker.js` | Офлайн и кэш |
| `lib/` | Исходный код Dart |
| `web/index.html` | Шаблон для `flutter build web` |

Артефакты сборки (`build/`, `.dart_tool/`, `.last_build_id` и др.) перечислены в `.gitignore`.

## Деплой

Размести содержимое корня (или `build/web/` после сборки) на любом хостинге статики. Для подпути укажи нужный `<base href="...">` в `index.html`.

## Требования

- Браузер с поддержкой WebAssembly (Chrome, Firefox, Safari, Edge).
- Для локального запуска — Python 3 или Node.js.
