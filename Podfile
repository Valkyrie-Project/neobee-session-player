platform :osx, '11.0'
use_frameworks!

inhibit_all_warnings!

# CocoaPods analytics can be disabled if needed
ENV['COCOAPODS_DISABLE_STATS'] = 'true'

abstract_target 'Pods-neobee-session-player' do
  target 'neobee-session-player' do
    pod 'VLCKit', '3.6.0'
  end

  target 'neobee-session-playerTests' do
    inherit! :search_paths
  end

  target 'neobee-session-playerUITests' do
    inherit! :search_paths
  end
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['MACOSX_DEPLOYMENT_TARGET'] = '11.0'
    end
  end
end
