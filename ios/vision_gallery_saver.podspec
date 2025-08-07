#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint vision_gallery_saver.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'vision_gallery_saver'
  s.version          = '1.0.0'
  s.summary          = 'A Flutter plugin for saving images and videos to the gallery.'
  s.description      = <<-DESC
Vision Gallery Saver allows saving images and videos to device gallery with advanced features.
                       DESC
  s.homepage         = 'https://github.com/EnsembleUI/vision_gallery_saver'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Name' => 'thenoumandev@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform         = :ios, '10.0'
  
  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 
    'DEFINES_MODULE' => 'YES', 
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' 
  }
  
  s.swift_version = '5.0'
end