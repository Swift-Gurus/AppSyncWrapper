#
# Be sure to run `pod lib lint AppSyncWrapper.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'AppSyncWrapper'
  s.version          = '0.2.0'
  s.summary          = 'Easy AppSync API. Helps avoid boilerplate code.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
Wraps around the AppSync API to make it easier to use. It also includes a decorator to handle Refresh Token issue.
                       DESC

  s.homepage         = 'https://github.com/aldo-dev/AppSyncWrapper'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'ALDO inc.' => 'aldodev@aldogroup.com' }
  s.source           = { :git => 'https://github.com/aldo-dev/AppSyncWrapper', :tag => s.version.to_s }
 

  s.ios.deployment_target = '11.0'
  s.swift_version = '5.0'

  s.source_files = 'AppSyncWrapper/Classes/**/*'
  
  s.dependency 'AWSAppSync'
  s.dependency 'EitherResult'
end
