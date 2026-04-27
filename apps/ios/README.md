# AV Photos iOS

Native SwiftUI iOS app for `AV Photos`.

## Current scope

This app scaffold establishes:

- native SwiftUI project structure
- local config pattern
- photo-library permission flow
- product shell for library, sync queue, and account tabs
- onboarding flow with continue or skip
- profile flow with language and theme preferences
- hosted backend reachability check
- authenticated remote asset listing when a local auth token is configured

Hosted upload, account auth, and real sync integration are still follow-up work.

## Local setup

1. Generate `Config/Local.xcconfig` from Infisical:
   `../../scripts/generate-local-xcconfig.sh local`
2. Generate the Xcode project:
   `xcodegen generate`
3. Open `AVPhotos.xcodeproj` in Xcode.

## Planned next work

- replace the local placeholder auth flow with real account/access state
- connect `prepare-upload`, upload, and `commit-upload`
- persist local queue state
- render remote hosted assets
