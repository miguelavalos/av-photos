# AV Photos iOS

Native SwiftUI iOS app for `AV Photos`.

## Current scope

This app scaffold establishes:

- native SwiftUI project structure
- local config pattern
- photo-library permission flow
- product shell for library, sync queue, and account tabs
- hosted backend reachability check
- authenticated remote asset listing when a local auth token is configured

Hosted upload, account auth, and real sync integration are still follow-up work.

## Local setup

1. Copy `Config/Local.xcconfig.example` to `Config/Local.xcconfig`.
2. Fill in any client-side values you want to use locally.
3. Generate the Xcode project:
   `xcodegen generate`
4. Open `AVPhotos.xcodeproj` in Xcode.

## Planned next work

- add real account/access state
- connect `prepare-upload`, upload, and `commit-upload`
- persist local queue state
- render remote hosted assets
