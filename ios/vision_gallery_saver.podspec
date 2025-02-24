#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint vision_gallery_saver.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'vision_gallery_saver'
  s.version          = '0.0.1'
  s.summary          = 'A Vision-powered Flutter plugin for saving media to gallery'
  s.description      = <<-DESC
A Flutter plugin that provides Vision-like precision for saving images and videos to device gallery.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '11.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end