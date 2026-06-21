# Alarmapp Local API

This API stores alarmapp tasks and activity records in local MariaDB.

## Endpoints

- `GET /health`
- `GET /api/tasks`
- `POST /api/tasks`
- `GET /api/tasks/{id}`
- `PUT /api/tasks/{id}`
- `DELETE /api/tasks/{id}`
- `GET /api/activities`
- `POST /api/activities`
- `GET /api/activities/{id}`
- `PUT /api/activities/{id}`
- `DELETE /api/activities/{id}`

The Flutter app calls this API at `http://localhost:8000` by default.
