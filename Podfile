# Uncomment the next line to define a global platform for your project
platform :ios, '11.0'
source 'https://github.com/CocoaPods/Specs.git'
target 'easy' do
  use_frameworks!

  pod 'Alamofire'
  pod 'RealmSwift'
  pod 'SwiftyJSON'
  pod 'PromiseKit'
  pod 'SwiftyUserDefaults'
  pod 'SwiftLint', :configuration => 'Debug'
  pod 'SnapKit'
  pod 'ESPullToRefresh'
  pod 'DifferenceKit'


  target 'easyTests' do
    inherit! :search_paths
    # Pods for testing
  end

end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      if config.name == 'Debug'
        config.build_settings['OTHER_SWIFT_FLAGS'] = ['$(inherited)', '-Onone']
        config.build_settings['SWIFT_OPTIMIZATION_LEVEL'] = '-Owholemodule'
      end
    end
  end
end