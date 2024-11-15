#
#  Be sure to run `pod spec lint qplayer2-core.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see https://guides.cocoapods.org/syntax/podspec.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |spec|



  spec.name         = "qplayer2-core"
  spec.version      = "1.5.0"
  spec.summary      = "Pili iOS video player SDK, RTMP, HLS video streaming supported."


  spec.homepage     = "https://github.com/pili-engineering/QPlayer2-IOS.git"
     
  spec.platform                = :ios
  spec.ios.deployment_target   = '10.0'
  spec.requires_arc            = true
  
  spec.pod_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }
  spec.user_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }


  spec.license      = "Apache License, Version 2.0"
  spec.author       = { "pili" => "pili-coresdk@qiniu.com" }
  spec.source       = { :http => "http://demovideos.qiniushawn.top/qplayer2-core-v#{spec.version}.zip" }

  spec.subspec "iphoneos" do |ss1|
      ss1.vendored_frameworks = ["Pod/Library/qplayer2_core.framework"]
  end
  spec.frameworks = ["UIKit", "Foundation","AVFoundation", "AudioToolbox", "QuartzCore", "OpenGLES", "CoreVideo","CoreMedia","VideoToolbox"]
  spec.libraries = ["c++", "bz2", "iconv","z"]



end
