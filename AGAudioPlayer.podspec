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

  s.platform     = :ios, '8.0'
  s.requires_arc = true

  s.source_files = 'AGAudioPlayer/**/*.{h,m}'
  s.resources = 'AGAudioPlayer/**/*.{xib}', 'AGAudioPlayer/UI/Icons.xcassets/*'

  # s.public_header_files = 'Pod/Classes/**/*.h'
  s.frameworks = 'MediaPlayer'
  s.dependency 'OrigamiEngine'
  s.dependency 'ASValueTrackingSlider'
  s.dependency 'MarqueeLabel'
  s.dependency 'NAKPlaybackIndicatorView'
  s.dependency 'LLACircularProgressView'
end