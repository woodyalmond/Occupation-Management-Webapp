# Alarmapp Flutter Source

This is a rebuilt Flutter source project for the existing alarmapp page.

## Local Run

Start the local API and MariaDB first from `projects/alarmapp`:

```bash
docker-compose up -d mariadb api
```

Then run the Flutter app from this folder:

```bash
flutter pub get
flutter run -d chrome
```

The app uses `http://127.0.0.1:8000` as its local CRUD API.

## Change API base URL

If `localhost` does not point to the machine running Docker (for example, remote SSH workflows), pass `API_BASE_URL`:

```bash
flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:8000
```
