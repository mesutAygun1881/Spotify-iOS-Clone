#!/bin/bash

# Script to update deployment target to iOS 15.0
echo "Updating deployment target to iOS 15.0..."

# Update project.pbxproj file with sed
sed -i '' 's/IPHONEOS_DEPLOYMENT_TARGET = [0-9]*\.[0-9]*/IPHONEOS_DEPLOYMENT_TARGET = 15.0/g' Spotify.xcodeproj/project.pbxproj
sed -i '' 's/"IPHONEOS_DEPLOYMENT_TARGET" => "[0-9]*\.[0-9]*"/"IPHONEOS_DEPLOYMENT_TARGET" => "15.0"/g' Spotify.xcodeproj/project.pbxproj

echo "Updating Podfile to iOS 15.0..."
# Update Podfile
sed -i '' 's/platform :ios, .*/platform :ios, '\''15.0'\''/g' Podfile

echo "Running pod install..."
# Run pod install
pod install

echo "Done! Now try building your project again." 