# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

target 'Precious Time' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!
  
  pod 'RxSwift', '6.5.0'
  pod 'RxCocoa', '6.5.0'

  target 'Precious TimeTests' do
    inherit! :search_paths
    pod 'RxBlocking', '6.5.0'
    pod 'RxTest', '6.5.0'
  end
end

post_install do |installer|
 installer.pods_project.targets.each do |target|
  target.build_configurations.each do |config|
   config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '12.0'
  end
 end
end
