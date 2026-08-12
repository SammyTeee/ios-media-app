# Media Remote

Media Remote is a small iPhone remote for media playing on a Windows PC. The iOS app connects to the companion Windows agent over a WebSocket on the local network and provides now-playing details plus play, pause, previous, and next controls.

## iOS build

The repository includes a complete Xcode project under `iOSApp/MediaRemoteApp.xcodeproj`. It targets iOS 17 or later and has no third-party package dependencies.

Every push to `main`, pull request, or manual workflow run builds the app on GitHub Actions using macOS 26 and Xcode 26.6 (which includes the iOS 26.5 SDK). The workflow uploads both an unsigned Simulator `.app` and an unsigned physical-device `.ipa` suitable for re-signing with Sideloadly.

Download the `MediaRemoteApp-sideloadly-*` artifact, unzip it, and load `MediaRemoteApp-unsigned.ipa` into Sideloadly. Sideloadly applies the Apple ID signing needed for installation on a physical iPhone. A free Apple Developer account normally needs refreshing every seven days; a paid account lasts longer.

The Windows workflow also publishes a self-contained `MediaAgent.exe`, so the companion can be downloaded and run without installing the .NET runtime.

## Connect the app

1. Start the Windows media agent on the PC with `dotnet run --project WindowsAgent/MediaAgent`.
2. Make sure the iPhone and PC are on the same network.
3. Open Media Remote and enter the PC's LAN address, for example `192.168.1.20:5000`. A Tailscale address such as `100.x.y.z:5000` works too.
4. Allow local-network access when iOS asks.

The app automatically adds `ws://`, port `5000` when omitted, and the `/ws` path.

The agent binds to `0.0.0.0:5000` by default, so it accepts connections through both the LAN and Tailscale. Set `MEDIA_REMOTE_URLS` before starting it if you want a narrower listen address. The first run may prompt for a Windows Firewall exception; only allow TCP port 5000 on trusted private/Tailscale networks because the remote-control protocol does not currently add its own authentication.

## Repository layout

- `iOSApp/` — SwiftUI iPhone app and Xcode project.
- `WindowsAgent/MediaAgent/` — companion Windows WebSocket service.
- `.github/workflows/ios-build.yml` — current GitHub-hosted Xcode build.
