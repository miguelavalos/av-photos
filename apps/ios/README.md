# AV Photos iOS

Native SwiftUI iOS app for `AV Photos`.

## Current scope

This app scaffold establishes:

- native SwiftUI project structure
- local config pattern
- photo-library permission flow
- product shell for library, sync queue, and account tabs
- onboarding flow with continue or skip
- real AV Apps account wiring through the configured account provider
- profile flow with language and theme preferences
- hosted backend reachability check
- authenticated remote asset listing using either a self-hosted token override or the signed-in account session

Hosted upload and end-to-end real sync validation are still follow-up work.

## Local setup

1. Install repo tooling from the repo root:
   `bun install`
2. Create `.infisical/bootstrap.env` from `.infisical/bootstrap.env.example`
3. Generate `Config/Local.xcconfig` from the repo root:
   `bun run ios:config`
4. Generate the Xcode project:
   `xcodegen generate`
5. Open `AVPhotos.xcodeproj` in Xcode.

## Planned next work

- connect `prepare-upload`, upload, and `commit-upload`
- validate end-to-end hosted sync with a real backend
- refine account entitlements and Pro gating
