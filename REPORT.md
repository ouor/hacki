# Android Build Report

Date: 2026-04-09

## Summary

Android debug build was attempted after installing Flutter and project dependencies.
The build did not complete because the local Android SDK Platform 36 installation is incomplete or corrupted.

## Commands Run

```powershell
flutter --version
flutter doctor -v
flutter pub get
flutter build apk --debug
.\gradlew.bat assembleDebug --stacktrace
```

## Observations

- `flutter --version` succeeded.
- `flutter pub get` succeeded.
- `flutter doctor -v` reported Android SDK issues:
  - `cmdline-tools component is missing`
  - `Android license status unknown`
- The project is configured for Android SDK 36 in [android/app/build.gradle](/C:/Users/SSAFY/Codes/Hacki/android/app/build.gradle).
- Multiple Flutter plugins in the project require `compileSdk 36`.
- The local SDK path contains `platforms/android-36`, but that directory is missing critical files such as `build.prop`.
- `platforms/android-35` is installed correctly, but lowering the app to SDK 35 is not a valid workaround because the plugin set requires SDK 36.

## Build Failure

Gradle ultimately failed with an Android platform resolution error:

```text
Failed to find target with hash string 'android-36'
```

And when the app was temporarily tested against SDK 35, plugin requirements blocked the build because several packages require Android SDK 36 or higher.

## Root Cause

The Android SDK Platform 36 installation on this machine is not healthy.
Flutter and Gradle can see the directory, but the platform contents are incomplete, so the Android target cannot be resolved during compilation.

## Recommended Fix

1. Reinstall `Android SDK Platform 36` from Android Studio SDK Manager.
2. Install or update Android `cmdline-tools`.
3. Accept Android licenses with:

```powershell
flutter doctor --android-licenses
```

4. Confirm that this file exists after reinstall:

```text
C:\Users\SSAFY\AppData\Local\Android\Sdk\platforms\android-36\build.prop
```

5. Re-run:

```powershell
flutter build apk --debug
```

## Result

The repository codebase was not proven broken by this build attempt.
The current blocker is the local Android SDK 36 environment.
