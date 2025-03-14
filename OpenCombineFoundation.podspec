Pod::Spec.new do |spec|
    spec.name          = "OpenCombineFoundation"
    spec.version       = "0.13.0"
    spec.summary       = "OpenCombine + OpenCombineFoundation interoperability"
  
    spec.description   = <<-DESC
    Adds publishers to Foundation types like NotificationCenter, URLSession etc.
    DESC
  
    spec.homepage      = "https://github.com/OpenCombine/OpenCombine/"
    spec.license       = "MIT"
  
    spec.authors       = { "Sergej Jaskiewicz" => "jaskiewiczs@icloud.com" }
    spec.source        = { :git => "https://github.com/OpenCombine/OpenCombine.git", :tag => "#{spec.version}" }
  
    spec.swift_version = "5.7"
  
    spec.osx.deployment_target     = "10.13"
    spec.ios.deployment_target     = "11.0"
    spec.watchos.deployment_target = "2.0"
    spec.tvos.deployment_target    = "11.0"
  
    spec.source_files = "Sources/OpenCombineFoundation/**/*.swift"
    spec.dependency     "OpenCombine", '>= 0.12.0'
  end
