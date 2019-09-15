Pod::Spec.new do |s|
  s.name             = 'RSXML2'
  s.version          = '2.0.0'
  s.summary          = 'This is utility code for parsing XML and HTML using libXML2’s SAX parser.'

  s.description      = <<-DESC
This is utility code for parsing XML and HTML using libXML2’s SAX parser.

It builds two framework targets: one for Mac, one for iOS. It does not depend on any other third-party frameworks. The code is Objective-C with ARC.
                       DESC

  s.homepage         = 'https://github.com/relikd/RSXML2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Oleg Geier' => '' }
  s.source           = { :git => 'https://github.com/relikd/RSXML2.git', :tag => s.version.to_s }

  s.ios.deployment_target = '8.0'
  s.osx.deployment_target  = '10.10'

  s.source_files = 'RSXML2/*'

  s.public_header_files = 'RSXML2/*.h'

  s.libraries = 'xml2.2'
  s.xcconfig = { 'HEADER_SEARCH_PATHS' => '$(SDKROOT)/usr/include/libxml2' }

end
