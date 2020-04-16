# Uncomment the next line to define a global platform for your project
platform :ios, '13.0'
source 'https://cdn.cocoapods.org/'
swift_version = "4.2"
inhibit_all_warnings!

target 'easy' do
  use_frameworks!
  pod 'SwiftLint', :configuration => 'Debug'

  target 'easyTests' do
    inherit! :search_paths
    # Pods for testing
  end

end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['DYLIB_COMPATIBILITY_VERSION'] = ''
      if config.name == 'Debug'
        config.build_settings['OTHER_SWIFT_FLAGS'] = ['$(inherited)', '-Onone']
        config.build_settings['SWIFT_OPTIMIZATION_LEVEL'] = '-Owholemodule'
      end
    end
  end
end