# traveltalkbd

A new Flutter project.

## Admin Chat Setup

To use the Chat tab in the admin panel (real-time chat with users), add your Firebase Auth UID to the Realtime Database:

1. Go to [Firebase Console](https://console.firebase.google.com) → your project → Realtime Database
2. Add a new node: `admins` → `{your-uid}` → `true`
3. Your UID can be found in Firebase Auth (Users tab) or by logging in and checking the URL/auth state

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
