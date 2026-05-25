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
  s.swift_versions = ['5.9', '5.10', '6.0']

  s.dependency 'SwiftProtobuf', '~> 1.28'

  s.subspec 'Core' do |core|
    core.source_files = 'Sources/TeslaBLEKeyKitCore/**/*.swift'
    core.exclude_files = 'Sources/TeslaBLEKeyKitCore/Protos/**'
  end

  s.subspec 'Crypto' do |crypto|
    crypto.source_files = 'Sources/TeslaBLEKeyKitCrypto/**/*.swift'
    crypto.dependency 'TeslaBLEKeyKit/Core'
  end

  s.subspec 'BLE' do |ble|
    ble.source_files = 'Sources/TeslaBLEKeyKitBLE/**/*.swift'
    ble.dependency 'TeslaBLEKeyKit/Core'
    ble.frameworks = 'CoreBluetooth'
  end

  s.subspec 'Kit' do |kit|
    kit.source_files = 'Sources/TeslaBLEKeyKit/**/*.swift'
    kit.exclude_files = 'Sources/TeslaBLEKeyKit/Protos/**'
    kit.resource_bundles = {
      'TeslaBLEKeyKit' => ['Sources/TeslaBLEKeyKit/PrivacyInfo.xcprivacy']
    }
    kit.dependency 'TeslaBLEKeyKit/Core'
    kit.dependency 'TeslaBLEKeyKit/Crypto'
    kit.dependency 'TeslaBLEKeyKit/BLE'
    kit.frameworks = 'Security'
  end

  s.default_subspec = 'Kit'
end
