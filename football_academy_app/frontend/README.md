# Football Academy Frontend

This is the frontend application for the Football Academy platform, built with Flutter.

## Project Structure

```
frontend/
├── lib/                    # Main source code
│   ├── main.dart          # Application entry point
│   ├── config/            # Configuration files
│   ├── models/            # Data models
│   ├── screens/           # UI screens
│   ├── widgets/           # Reusable UI components
│   ├── services/          # API and business logic services
│   └── utils/             # Utility functions
├── assets/                # Static assets (images, fonts, etc.)
├── test/                  # Test files
└── pubspec.yaml          # Flutter dependencies and configuration
```

## Setup

1. Install Flutter:
   - Follow the [Flutter installation guide](https://flutter.dev/docs/get-started/install)
   - Make sure you have Flutter SDK in your PATH

2. Install dependencies:
```bash
flutter pub get
```

3. Run the application:
```bash
flutter run
```

## Features

- User authentication (login/register)
- Player profile management
- Training plan viewing and tracking
- Exercise video playback
- Achievement tracking
- Player statistics visualization
- FIFA-style player card display

## Development

The frontend communicates with the backend API running at `http://localhost:8000`.

## License

This project is licensed under the MIT License - see the LICENSE file for details. 