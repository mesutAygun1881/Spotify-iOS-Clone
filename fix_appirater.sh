#!/bin/bash

echo "Fixing Appirater pod dependency issue..."

# Create directory if it doesn't exist
sudo mkdir -p /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/arc/

# Create empty placeholder files
echo "Creating empty placeholder files for libarclite..."
touch /tmp/libarclite_iphoneos.a
touch /tmp/libarclite_iphonesimulator.a

# Copy the placeholder files to the Xcode toolchain
echo "Copying placeholder files to Xcode toolchain directory..."
sudo cp /tmp/libarclite_iphoneos.a /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/arc/
sudo cp /tmp/libarclite_iphonesimulator.a /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/arc/

echo "Removing Appirater pod and reinstalling with a newer version..."
# Edit the Podfile to use a specific version of Appirater that's compatible with newer iOS versions
sed -i '' 's/pod '\''Appirater'\''/pod '\''Appirater'\'', '\''~> 2.3.1'\''/g' Podfile

# Clean CocoaPods cache and reinstall
echo "Running pod install with clean cache..."
pod cache clean Appirater
pod install

echo "Done! The issue should be fixed now. Please try building your project again." 