#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint cashfree_pg.podspec' to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'cashfree_pg'
  s.version          = '0.0.1'
  s.summary          = 'Official Flutter plugin for Cashfree PG.'
  s.description      = <<-DESC
A new Flutter plugin.
                       DESC
  s.homepage         = 'http://www.cashfree.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Cashfree' => 'arjun@cashfree.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  #s.platform = :ios, '10.1'

  # Flutter.framework does not contain a i386 slice. Only x86_64 simulators are supported.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'VALID_ARCHS[sdk=iphonesimulator*]' => 'x86_64' }
  s.swift_version = '5.0'
  # s.preserve_paths = 'CFSDK.xcframework'
  # s.resources = ['CFSDK.xcframework']
  # s.xcconfig = { 'OTHER_LDFLAGS' => '-framework CFSDK' }
  s.vendored_frameworks = 'CFSDK.xcframework'
end
