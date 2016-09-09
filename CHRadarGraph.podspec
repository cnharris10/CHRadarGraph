#
# Be sure to run `pod lib lint CHRadarGraph.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "CHRadarGraph"
  s.version          = "0.1.5"
  s.summary          = "Create a circular bar graph."

  s.description      = <<-DESC
    Create a circular bar graph. Supports Swift 2.x / iOS 9+
                       DESC

  s.homepage         = "https://github.com/cnharris10/CHRadarGraph"
  s.license          = 'MIT'
  s.author           = { "Christopher Harris" => "cnharris@gmail.com" }
  s.source           = { :git => "https://github.com/cnharris10/CHRadarGraph.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/cnharris10'

  s.platform     = :ios, '9.0'
  s.requires_arc = true

  s.source_files = 'Pod/Classes/**/*'
  s.frameworks = 'UIKit'
end
