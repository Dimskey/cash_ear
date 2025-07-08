# Warkop Mbak Tata

## Setup Instructions

1. **Install Flutter**
   - Follow the official guide: https://docs.flutter.dev/get-started/install

2. **Clone this repository**
   ```sh
   git clone <repo-url>
   cd warkoptata
   ```

3. **Install dependencies**
   ```sh
   flutter pub get
   ```

4. **Setup Firebase**
   - Create a Firebase project at https://console.firebase.google.com/
   - Add Android/iOS app and download `google-services.json`/`GoogleService-Info.plist` to the respective folders.
   - Enable Authentication and Firestore in Firebase console.

5. **Run the app**
   ```sh
   flutter run
   ```

6. **Notes**
   - Make sure you have an emulator or device connected.
   - For notifications, additional setup may be required (see `lib/services/notification_service.dart`).
