Pod::Spec.new do |s|
  s.name         = 'TeslaBLEKeyKit'
  s.version      = '0.1.0'
  s.summary      = 'Swift library for communicating with Tesla vehicles over BLE.'
  s.description  = <<-DESC
    TeslaBLEKeyKit wraps the BLE transport, universal-message session
    authentication, and VCSEC commands for talking to Tesla vehicles
    over the local BLE command protocol.
  DESC
  s.homepage     = 'https://github.com/misakatao/TeslaBLEKeyKit'
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.author       = { 'misakatao' => 'misakatao@gmail.com' }
  s.source       = { :git => 'https://github.com/misakatao/TeslaBLEKeyKit.git', :tag => s.version.to_s }

  s.ios.deployment_target = '16.0'
  s.osx.deployment_target = '13.0'
  s.watchos.deployment_target = '9.0'
  s.tvos.deployment_target = '16.0'
  s.visionos.deployment_target = '1.0'
  s.swift_versions = ['5.9', '5.10', '6.0']

  s.source_files = 'Sources/**/*.swift'
  s.exclude_files = [
    'Sources/TeslaBLEKeyKit/Protos/**',
    'Sources/TeslaBLEKeyKitExample/**'
  ]

  s.frameworks = 'CoreBluetooth', 'Security'

  s.dependency 'SwiftProtobuf', '~> 1.28'
end
