# AV Photos iOS Installation

This guide covers the current local scaffold for `AV Photos` on iOS.

## Prerequisites

1. Xcode 16 or later
2. `xcodegen` installed locally
3. A local `Config/Local.xcconfig`

## Setup

1. Open `public/av-photos/apps/ios`
2. Copy:
   `Config/Local.xcconfig.example` -> `Config/Local.xcconfig`
3. Adjust any local values you want to use
   Optional:
   - set `AVPHOTOS_AVAPPS_API_BASE_URL` to a hosted or self-hosted backend
   - set `AVPHOTOS_AUTH_TOKEN` to a local bearer token if you want to test authenticated hosted reads
4. Generate the project:
   `xcodegen generate`
5. Open `AVPhotos.xcodeproj`
6. Run the `AVPhotos` scheme on simulator or device

## Current scope

The current app scaffold includes:

- SwiftUI shell
- photo-library permission flow
- library, sync, and account tabs
- local client config pattern
- hosted backend reachability check
- authenticated remote asset listing when a local auth token is configured

It does not yet include:

- real account auth
- hosted upload integration
- persisted sync queue
- remote asset listing
