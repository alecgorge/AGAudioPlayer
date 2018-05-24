Pod::Spec.new do |s|
  s.name             = "AGAudioPlayer"
  s.version          = "0.8.0"
  s.summary          = "Gapless-playback + UI"
  # s.description      = <<-DESC
  #                      An optional longer description of ${POD_NAME}
  #                      * Markdown format.
  #                      * Don't worry about the indent, we strip it!
  #                      DESC
  s.homepage         = "https://github.com/alecgorge/AGAudioPlayer"
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"
  s.license          = 'MIT'
  s.author           = { "alecgorge" => "alecgorge@gmail.com" }
  s.source           = { :git => "https://github.com/alecgorge/AGAudioPlayer.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/alecgorge'

  s.ios.deployment_target = '11.0'
  s.osx.deployment_target = '10.11'
  s.requires_arc = true

  s.source_files = 'AGAudioPlayer/**/*.{h,m,swift}'

  # s.public_header_files = 'Pod/Classes/**/*.h'
  s.ios.frameworks = 'MediaPlayer'
  s.resource_bundle = { 'AGAudioPlayer' => ['AGAudioPlayer/UI/Icons.xcassets', 'AGAudioPlayer/**/*.xib'] }
  
  s.dependency 'Interpolate'
  s.dependency 'BASSGaplessAudioPlayer'
  s.dependency 'MarqueeLabel'
  s.dependency 'NapySlider'
  s.dependency 'BCColor'
end
