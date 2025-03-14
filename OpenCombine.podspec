Pod::Spec.new do |spec|
  spec.name          = "OpenCombine"
  spec.version       = "0.13.0"
  spec.summary       = "Open source implementation of Apple's Combine framework for processing values over time."

  spec.description   = <<-DESC
  An open source implementation of Apple's Combine framework for processing values over time.
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

  spec.source_files        = "Sources/COpenCombineHelpers/**/*.{h,cpp}", "Sources/OpenCombine/**/*.swift"
  spec.public_header_files = "Sources/COpenCombineHelpers/include/*.h"

  spec.libraries = "c++"
end
