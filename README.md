# seon_orchestration_flutter

[iOS](https://www.apple.com/ios/)
[Android](https://developer.android.com/about/versions/oreo)
[License: MIT](https://opensource.org/licenses/MIT)

Flutter plugin for the [SEON Orchestration SDK](https://seon.io/), providing identity verification flows for iOS and Android. Built using Flutter’s `MethodChannel` for communication between Dart and native code.

## Features

- **Cross-platform** — One Dart API on iOS and Android
- **MethodChannel** — Standard Flutter platform channel integration
- **Typed API** — Dart classes and enums for configuration and results

## Installation

Add the dependency to your `pubspec.yaml`:

```yaml
dependencies:
  seon_orchestration_flutter: ^1.0.5   # use pub.dev once published
```

For a local checkout during development:

```yaml
dependencies:
  seon_orchestration_flutter:
    path: ../seon-orchestration-flutter
```

For iOS, install CocoaPods dependencies:

```sh
cd ios && pod install
```

## Quick start

```dart
import 'package:seon_orchestration_flutter/seon_orchestration_flutter.dart';

// 1. Initialize the SDK
await SeonOrchestration.initialize(const SeonConfig(
  baseUrl: 'https://your-api-endpoint.com',
  token: 'your-auth-token',
  language: 'en', // optional
));

// 2. Start the verification flow
final result = await SeonOrchestration.startVerification();

switch (result.status) {
  case SeonVerificationStatus.completedSuccess:
    print('Verification passed!');
    break;
  case SeonVerificationStatus.completedFailed:
    print('Verification failed.');
    break;
  case SeonVerificationStatus.interruptedByUser:
    print('User cancelled.');
    break;
  case SeonVerificationStatus.error:
    print('Error: ${result.errorMessage}');
    break;
  default:
    break;
}
```

### Custom theme

The `theme` parameter is a `Map<String, dynamic>` that is JSON-encoded for the native SDK. See [SEON workflow initialization](https://docs.seon.io) for the full theme schema.

```dart
await SeonOrchestration.initialize(SeonConfig(
  baseUrl: 'https://your-api-endpoint.com',
  token: 'your-auth-token',
  language: 'en',
  theme: { /* your theme config */ },
));
```

### Cleanup

```dart
await SeonOrchestration.dispose();
```

## API overview


| Method                                  | Description                                              |
| --------------------------------------- | -------------------------------------------------------- |
| `SeonOrchestration.initialize(config)`  | Initialize with base URL, token, optional language/theme |
| `SeonOrchestration.startVerification()` | Present verification UI and return the result            |
| `SeonOrchestration.dispose()`           | Release native resources                                 |



| Type                     | Description                      |
| ------------------------ | -------------------------------- |
| `SeonConfig`             | Configuration for `initialize()` |
| `SeonVerificationResult` | Result of `startVerification()`  |
| `SeonVerificationStatus` | Verification outcome enum        |
| `SeonErrorCode`          | SDK error codes                  |
| `SeonException`          | Thrown on SDK errors             |


## Platform requirements


| Platform | Minimum               |
| -------- | --------------------- |
| iOS      | 13.0+ (see `ios/seon_orchestration_flutter.podspec`) |
| Android  | API 26+ / Android 8.0+ (see `android/build.gradle`) |
| Flutter  | ≥3.16.0 (see `pubspec.yaml` `environment.flutter`) |


## Permissions

The SEON SDK may require camera, microphone, and storage. Location is optional if your workflow uses it.

### iOS (`Info.plist`)

```xml
<key>NSCameraUsageDescription</key>
<string>Required for ID verification and selfie capture</string>
<key>NSMicrophoneUsageDescription</key>
<string>Required for video liveness checks</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Required for proof of address document upload</string>
```

### Android

The plugin merges required permissions into your app manifest. For location-based checks, add `ACCESS_FINE_LOCATION` and the matching iOS location usage key.

## Documentation

Hosted documentation (introduction and guides): [SEON Orchestration Flutter — Introduction](https://jdev-e8db0569.mintlify.app/introduction).

For this repository’s Mintlify source (when present), run locally:

```sh
npm i -g mintlify
cd docs
mintlify dev
```

## Sample app

**Layout:** In the plugin development repository, the runnable app is under [`example/`](example/). In the [public sample repository](https://github.com/seontechnologies/seon-orchestration-flutter), the same app is at the **repository root**—run `flutter pub get` and `flutter run` there.

From the sample directory (repository root in the public repo, or `example/` here):

```sh
flutter pub get
flutter run
```

## License

MIT

## Changelog

### 1.0.5

- Updated native iOS `SEONOrchSDK` to 1.0.3
- Updated native Android `orchestration-android-sdk` to 1.0.1

### 1.0.4

- Minor Improvements

### 1.0.3

- NFC Verification
- Minor Improvements

### 0.1.1

- Documentation enhancement.

### 0.1.0

- Initial version.