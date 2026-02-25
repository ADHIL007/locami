# Locami

**Locami** is an offline-first location alert app built with Flutter.  
It helps users get notified when they approach a chosen destination — even without internet connectivity.

Designed especially for commuters and bus travelers, Locami ensures you never miss your stop while sleeping or distracted.

---

## Design Concept

<img width="624" height="1024" alt="locami" src="https://github.com/user-attachments/assets/77e428e7-b0a4-431c-b842-3195e6918140" />

## Features

- Fully offline location tracking (no internet required)
- GNSS-based distance monitoring
- Smart geofence alert system
- Background tracking support
- Lightweight and battery-conscious
- Simple and fast destination setup
- Designed for commuters and bus travel
- Privacy-friendly (all processing on device)

---

## How It Works

1. User selects a destination.
2. Locami continuously monitors device location using GNSS.
3. Distance to destination is calculated locally.
4. When the user enters the alert radius, an alarm is triggered.

No maps API. No network dependency.

---

## Tech Stack

- Flutter
- Dart
- Android foreground services
- Device GNSS (GPS/GLONASS/Galileo/BeiDou)
- Sensor-based movement detection

---

## Use Cases

- Bus passengers who sleep during travel
- Daily commuters
- Train travelers
- Location-based personal reminders
- Offline travel assistance

---

## Getting Started

### Prerequisites

- Flutter SDK installed
- Android Studio or VS Code
- Android device/emulator with location enabled

### Installation

```bash
git clone https://github.com/your-username/locami.git
cd locami
flutter pub get
flutter run
