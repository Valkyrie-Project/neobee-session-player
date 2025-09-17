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
      
      # 确保VLCKit被嵌入到app bundle中
      if target.name == 'VLCKit'
        config.build_settings['BUILD_LIBRARY_FOR_DISTRIBUTION'] = 'YES'
        config.build_settings['SKIP_INSTALL'] = 'NO'
      end
    end
  end
  
  # 确保VLCKit被复制到app bundle
  installer.pods_project.targets.each do |target|
    if target.name == 'VLCKit'
      target.build_phases.each do |phase|
        if phase.is_a?(Xcodeproj::Project::Object::PBXCopyFilesBuildPhase)
          phase.dst_subfolder_spec = '10' # Frameworks folder
        end
      end
    end
  end
end
