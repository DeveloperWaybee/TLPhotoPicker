#
# Be sure to run `pod lib lint DW_TLPhotoPicker.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'DW_TLPhotoPicker'
  s.version          = '1.0.5'
  s.summary          = 'multiple phassets picker for iOS lib. like facebook'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = 'Multiple image/video assets picker for iOS lib, like facebook. It is a simple and easy-to-use library that allows you to select multiple images and videos from the photo library. It supports both image and video selection, and provides a customizable UI for selecting assets. The library is built using Swift and is compatible with iOS 9.1 and above.'

  s.homepage         = 'https://github.com/DeveloperWaybee/TLPhotoPicker'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'DeveloperWaybee' => 'developer@waybeetech.com' }
  s.source           = { :git => 'https://github.com/DeveloperWaybee/TLPhotoPicker.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '9.1'
  s.swift_version = '5.0'
  s.pod_target_xcconfig = { 'SWIFT_VERSION' => '5.0' }

  s.source_files = 'DW_TLPhotoPicker/Classes/**/*.swift'
  
  s.resource_bundles = { 'DW_TLPhotoPicker' => ['DW_TLPhotoPicker/Classes/*.xib'] }
  s.resources = 'DW_TLPhotoPicker/DW_TLPhotoPickerController.bundle'

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
