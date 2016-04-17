#
# Be sure to run `pod lib lint CHRadarGraph.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "CHRadarGraph"
  s.version          = "0.1.2"
  s.summary          = "Create a circular bar graph."

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!  
  s.description      = <<-DESC
    Create a circular bar graph. Supports Swift 2.2+
                       DESC

  s.homepage         = "https://github.com/cnharris10/CHRadarGraph"
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"
  s.license          = 'MIT'
  s.author           = { "Christopher Harris" => "cnharris@gmail.com" }
  s.source           = { :git => "https://github.com/cnharris10/CHRadarGraph.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/cnharris10'

  s.platform     = :ios, '9.0'
  s.requires_arc = true

  s.source_files = 'Pod/Classes/**/*'
  s.resource_bundles = {
    'CHRadarGraph' => ['Pod/Assets/*.png']
  }

  s.frameworks = 'UIKit'
end
