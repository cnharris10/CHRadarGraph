#
# Be sure to run `pod lib lint CHRadarGraph.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'CHRadarGraph'
  s.version          = '0.3.0'
  s.summary          = 'An easy utility to create a radar graph.'
  s.homepage         = 'https://github.com/cnharris10/CHRadarGraph'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Christopher Harris' => 'cnharris@gmail.com' }
  s.source           = { :git => 'https://github.com/cnharris10/CHRadarGraph.git', :tag => s.version.to_s }
  s.readme = "https://github.com/cnharris10/CHRadarGraph/blob/0.3.0/README.md"


  s.ios.deployment_target = '13.0'
  s.swift_versions = '5.0'

  s.source_files = 'Classes/**/*'
end
