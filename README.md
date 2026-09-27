# Mindar

Voice Calendar app: "Speak a thought. Give it a day. Let the rest unfold."

## Structure

```
mindar/
  backend/    Spring Boot 3 (Java 17) REST API
  frontend/   Flutter app (Android + iOS) — Mindar
```

## Backend — run locally

```bash
cd backend
./mvnw spring-boot:run
```

Runs on `http://localhost:8080` with an in-memory H2 database (data resets
on restart — swap the `application-prod.properties` profile + a Postgres
instance for anything real). Endpoints:

- `POST /api/auth/register` `{displayName, email, password}` → `{token, userId, ...}`
- `POST /api/auth/login` `{email, password}` → `{token, ...}`
- `POST /api/events` `{eventType, eventDate, transcript, title?}` (auth required)
- `GET /api/events?start=YYYY-MM-DD&end=YYYY-MM-DD`
- `GET /api/events/day/{date}`
- `PATCH /api/events/{id}` `{title?, transcript?, completed?}`
- `DELETE /api/events/{id}`

`eventType` is one of `LEARNING_CONCEPT`, `MEETING`, `TODO`.

Set a real JWT secret via the `MINDAR_JWT_SECRET` env var before deploying —
the default in `application.properties` is a placeholder.

## Frontend — run locally

```bash
cd frontend
flutter pub get
flutter run --dart-define=MINDAR_API_BASE_URL=http://10.0.2.2:8080/api
```

- Use `http://10.0.2.2:8080/api` as the base URL for the **Android emulator**
  (it maps to your host machine's localhost).
- Use `http://localhost:8080/api` for the **iOS simulator**.
- Use your machine's LAN IP (e.g. `http://192.168.1.20:8080/api`) for a
  physical device on the same network.

### Permissions to add before building

- **Android** (`android/app/src/main/AndroidManifest.xml`): add
  `<uses-permission android:name="android.permission.RECORD_AUDIO"/>` and
  `<uses-permission android:name="android.permission.INTERNET"/>`.
- **iOS** (`ios/Runner/Info.plist`): add `NSMicrophoneUsageDescription` and
  `NSSpeechRecognitionUsageDescription` with a short explanation string,
  since `speech_to_text` needs both on iOS.

## Flow implemented

1. **Splash** — Mindar icon, then the slogan "Free Space for what Matters!",
   then routes to Login or straight to the calendar if a session exists.
2. **Register / Login** — simple email + password, backed by the Spring Boot
   auth endpoints, JWT stored in secure storage.
3. **Calendar (main screen)** — day/week/month toggle, a summary bar with
   per-type counts, and a notes panel for the selected day, styled after the
   reference design.
4. **Tap a day (or "New thought")** → bottom sheet to pick an event type
   (Learning concept / Meeting / To-do) → voice-input dialog that transcribes
   speech live on-device → saves the transcript to the backend tied to that
   day and type.

## Notes / next steps

- Speech-to-text runs via the OS APIs (`speech_to_text` package); only the
  final transcript is sent over the network, not audio.
- The month grid currently fetches one month at a time; the week/day toggle
  reuses the same data since `table_calendar` handles the layout switch.
- Add password-reset, richer to-do editing (checkbox toggle is wired up in
  the API service via `toggleTodoComplete`, just not yet in the UI), and
  push notifications for reminders as natural next iterations.
