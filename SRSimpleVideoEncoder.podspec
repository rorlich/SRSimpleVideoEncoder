Pod::Spec.new do |s|

  s.name         = "SRSimpleVideoEncoder.podspec"
  s.version      = "1.0"
  s.summary      = "A library for encoding NSArray<UIImage*>* to video"

  s.description  = "SRSimpleVideoEncoder  provides an easy-to-use tool for encoding UIImages array."

  s.homepage     = "https://github.com/Visualead/SRSimpleVideoEncoder.git"

  s.license      = { :type => "MIT", :file => "LICENSE" }

  s.author             = { "Sagi Rorlich" => "sagir@visualead.com" }
  s.social_media_url   = "http://facebook.com/rorlich.sagi"

  s.platform     = :ios, "8.0"

  s.source       = { :git => "https://github.com/rorlich/SRSimpleVideoEncoder.git"  }

  s.source_files  = "Source"

  s.framework  = "AVFoundation" , "AVKit"

  s.requires_arc = true

end
