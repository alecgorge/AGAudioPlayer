inhibit_all_warnings!
use_frameworks!

target "AGAudioPlayer" do
    platform :ios, '11.0'

    pod 'Interpolate'
    pod 'BASSGaplessAudioPlayer', :path => '../gapless-audio-bass-ios'
    pod 'MarqueeLabel'
    pod 'NapySlider'
    # pod 'HysteriaPlayer', :head
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['ENABLE_BITCODE'] = 'NO'
    end
  end
end

=begin
target "AGAudioPlayerOSX" do
    platform :osx, '10.11'
    
    pod 'FreeStreamer'
    # pod 'HysteriaPlayer', :head
end
=end

