# ResQ Pet AI - Mobile Application

Flutter mobile application for citizens, rescue volunteers, and NGO coordinators.

## Status

🚧 **Next implementation phase** — reuse selected, attributed Flutter patterns from the owned Animal Welfare app after backend contracts pass.

## Planned Features

- Authentication screens
- Rescue case reporting
- Volunteer case assignment view
- Status update functionality
- Real-time WebSocket updates
- Offline draft saving
- Image compression
- Bilingual support (English/Urdu)

## Technology Stack

- Flutter SDK 3.10+
- Dart 3.0+
- State Management: Provider or Riverpod
- HTTP Client: dio or http
- WebSocket: web_socket_channel
- Secure Storage: flutter_secure_storage

## Setup (When Implemented)

```bash
cd mobile

# Get dependencies
flutter pub get

# Run on connected device/emulator
flutter run

# Build release APK
flutter build apk --release --obfuscate --split-debug-info=build/debug-info
```

## Directory Structure (Planned)

```
mobile/
├── lib/
│   ├── main.dart
│   ├── core/
│   ├── features/
│   └── shared/
├── test/
├── assets/
└── pubspec.yaml
```
