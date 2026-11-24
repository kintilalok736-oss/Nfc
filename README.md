# Tap Me

A Flutter starter for Alvin Khoiri's social-link profile: WhatsApp, Instagram, and TikTok. The app includes a grey profile UI, local profile editing, NFC NDEF URL writing, and QR display.

## Requirements

- Flutter stable SDK (Dart 3.3+)
- Android device with NFC for tag writing; iPhone NFC reading/writing support depends on device/iOS and tag compatibility
- An HTTPS public profile page URL before programming tags. NFC/QR must point to a page that other phones can open; the app's local profile data is not itself publicly hosted.

## Run

```sh
flutter pub get
flutter run
```

## Configure a public profile URL

Open Edit profile and enter the deployed HTTPS profile URL. Then use **Program tag NFC** and hold a writable NDEF tag near the phone. The QR button uses the same URL. Use NDEF-compatible tags; tag capacity and phone support vary.

## Supabase

`supabase/schema.sql` contains the initial database schema. Run it in the Supabase SQL Editor. The mobile app is currently local-first and does not yet sync to Supabase or publish a public profile page. Supabase URL alone is not sufficient to connect: configure a publishable/anon key securely as a build-time public client setting, and implement authentication plus owner-only RLS policies before enabling profile editing in the cloud. Never ship a `service_role` key in a mobile application.

## Build notes

This repository contains the Flutter app source and database schema. Generate platform folders if absent with `flutter create .`, then enable NFC permissions/entitlements as required by the target Android/iOS versions. NFC writing and cross-platform behavior should be tested on physical devices.
