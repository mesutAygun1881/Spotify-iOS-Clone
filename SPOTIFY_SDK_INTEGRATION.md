# Spotify iOS SDK Integration Guide

## Overview

This document provides instructions on how to integrate the real Spotify iOS SDK into this project. Currently, the project uses a mock implementation of the Spotify iOS SDK for demonstration purposes.

## Prerequisites

1. A Spotify Developer account
2. A registered Spotify application with proper redirect URIs
3. Access to the Spotify iOS SDK

## Step 1: Download the Spotify iOS SDK

1. Go to the [Spotify Developer Dashboard](https://developer.spotify.com/dashboard)
2. Log in with your Spotify account
3. Download the latest version of the iOS SDK

## Step 2: Add the Spotify iOS SDK to your project

### Option 1: Manual Integration

1. Extract the downloaded SDK
2. Drag the `SpotifyiOS.framework` into your Xcode project
3. Make sure "Copy items if needed" is checked and add it to your target
4. Go to your target's Build Phases and add SpotifyiOS.framework to "Link Binary With Libraries"
5. Add `-ObjC` to your target's "Other Linker Flags" in Build Settings

### Option 2: Swift Package Manager

If Spotify provides SPM support in the future, use the following steps:

1. In Xcode, go to File > Swift Packages > Add Package Dependency
2. Enter the URL for the Spotify iOS SDK package
3. Follow the prompts to add the package to your project

## Step 3: Update your Info.plist

Your Info.plist already contains the necessary URL schemes, but ensure the following are present:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLName</key>
        <string>com.spotify.ios-sdk-auth</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>spotify-sdk-YOUR_CLIENT_ID</string>
        </array>
    </dict>
</array>
<key>LSApplicationQueriesSchemes</key>
<array>
    <string>spotify</string>
    <string>spotify-sdk</string>
</array>
```

Replace `YOUR_CLIENT_ID` with your actual Spotify client ID.

## Step 4: Replace the Mock Implementation

1. Remove the mock implementation files:
   - `Managers/SpotifyiOS.swift`

2. Update imports in the following files to use the real SpotifyiOS SDK:
   - `Controllers/Core/HomeViewController.swift`
   - `Resources/AppDelegate.swift`
   - `Managers/SpotifyAppRemoteManager.swift`

3. In each file, add:
   ```swift
   import SpotifyiOS
   ```

## Step 5: Update the SpotifyAppRemoteManager

The SpotifyAppRemoteManager is already implemented to work with the real Spotify SDK once it's integrated. Key functionalities include:

- Connect to the Spotify app
- Fetch now playing information
- Fetch the playback queue
- Retrieve playlist information

## Step 6: Test the Integration

1. Ensure the Spotify app is installed on your device
2. Build and run the app
3. Log in with your Spotify account
4. Start playing a song in the Spotify app
5. Verify that the "Now Playing" section in your app displays the current song

## Troubleshooting

1. **Connection Issues**: Ensure that the Spotify app is installed and that you're using the correct client ID
2. **Authentication Issues**: Verify that your redirect URIs are properly set up in your Spotify Developer Dashboard
3. **Framework Issues**: Make sure the SpotifyiOS.framework is properly linked and the -ObjC flag is added

## Additional Resources

- [Spotify iOS SDK Documentation](https://developer.spotify.com/documentation/ios/)
- [Spotify Developer Dashboard](https://developer.spotify.com/dashboard/)
- [Spotify Web API Documentation](https://developer.spotify.com/documentation/web-api/) 