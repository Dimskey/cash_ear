# Cash Ear

**Cash Ear** is a modern Point of Sales (POS) application for small businesses, cafes, and retail stores. Built with Flutter and Firebase, it helps you manage products, sales, and inventory directly from your Android device.

---

## Features

- Product management with images, categories, prices, and stock levels
- Sales tracking and daily profit reports
- Secure login and registration (Firebase Authentication)
- Image upload for products (Firebase Storage)
- Role management (admin/cashier)
- Local notifications for important events (e.g., low stock)
- Modern, clean UI
- Offline support (Firestore offline persistence)

---

## ⚠️ Sensitive Data Removed

This repository **does not include any sensitive data or credentials**.  
You must provide your own Firebase configuration to run the app.

### **What you need to set up:**
1. **Firebase Project**
   - Create a new project at [Firebase Console](https://console.firebase.google.com/).
   - Add an Android app (use your own package name, e.g., `com.yourcompany.cashear`).
   - Download `google-services.json` and place it in `android/app/`.
   - Enable Authentication, Firestore, and Storage in your Firebase project.

2. **App Configuration**
   - Update the package name in `android/app/build.gradle.kts` and `AndroidManifest.xml` if needed.
   - Make sure your `pubspec.yaml` dependencies are up to date (`flutter pub get`).

3. **(Optional) Customization**
   - Change the app name/logo if desired.
   - Update Firestore security rules for your use case.

---

## Getting Started

1. **Clone this repository:**
   ```sh
   git clone https://github.com/yourusername/cash-ear.git
   cd cash-ear
   ```

2. **Install dependencies:**
   ```sh
   flutter pub get
   ```

3. **Add your Firebase config:**
   - Place your `google-services.json` in `android/app/`.

4. **Run the app:**
   ```sh
   flutter run
   ```

---

## Screenshots

_Add your screenshots here to showcase the app UI._

---

## License

This project is licensed under the MIT License.
