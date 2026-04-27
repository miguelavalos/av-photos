# AV Photos Roadmap

This repository tracks the public client for `AV Photos`.

## Current scope

- native SwiftUI iOS app
- photo-library permission flow
- local-first shell
- preparation for hosted and self-hosted sync modes

## Near-term work

1. Wire the iOS client to the hosted upload flow
2. Persist the local sync queue
3. Render uploaded remote assets in the app
4. Harden retry, delete, and account-isolation behavior

## Product boundaries for v1

- iOS only
- selective sync, not full automatic device backup
- no Android
- no macOS client yet
- no sharing or social features
- no dependence on private production credentials in the public client
