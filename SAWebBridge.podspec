Pod::Spec.new do |s|
  s.name         = "SAWebBridge"
  s.version      = "1.0.1"
  s.license      = 'MIT'
  s.summary      = "A web bridge for swift H5 project"
  s.author       = { "sarkizz" => "sarkizz@yahoo.com.sg" }
  s.homepage     = "https://github.com/Sarkizz"
  s.source       = { :git => "https://github.com/Sarkizz/SAWebBridge.git", :tag => s.version.to_s}
  s.platform     = :ios, "11.0"
  s.ios.deployment_target = "11.0"
  s.requires_arc = true
  s.swift_version = "5.0"

  s.subspec 'WebBridge' do |ss|
    ss.source_files = "SAWebBridge/WebBridge/*.swift"
    ss.ios.frameworks = "UIKit", "Foundation", "WebKit"

    ss.subspec 'Utils' do |sss|
      sss.source_files = "SAWebBridge/WebBridge/Utils/*.swift"
      sss.ios.frameworks = "UIKit", "Foundation"
    end
  end
  s.resource = "SAWebBridge/JS/*.js"

end
