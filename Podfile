# Platform configuration
platform :ios, '15.0'

target 'Spotify' do
  use_frameworks!

  # The only dependency we need
  pod 'SDWebImage'
  
  # Commented out problematic dependencies
  # pod 'Appirater'
  # pod 'Firebase/Analytics'
end

# Post-install hook to ensure all pods use iOS 15.0 minimum
post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
      # Disable code signing for pods
      config.build_settings['CODE_SIGNING_ALLOWED'] = 'NO'
      # Disable bitcode
      config.build_settings['ENABLE_BITCODE'] = 'NO'
    end
  end
end
