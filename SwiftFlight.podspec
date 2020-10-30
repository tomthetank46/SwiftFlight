Pod::Spec.new do |s|

# 1
s.platform = :ios
s.ios.deployment_target = '13.0'
s.name = "SwiftFlight"
s.summary = "SwiftFlight lets a user interact with the Infinite Flight Simulator Connect API."
s.requires_arc = true

# 2
s.version = "0.1.0"

# 3
s.license = { :type => "MIT", :file => "LICENSE" }

# 4 - Replace with your name and e-mail address
s.author = { "Thomas Hogrefe" => "tomhogrefe46@gmail.com" }

# 5 - Replace this URL with your own GitHub page's URL (from the address bar)
s.homepage = "https://github.com/tomthetank46/SwiftFlight"

# 6 - Replace this URL with your own Git URL from "Quick Setup"
s.source = { :git => "https://github.com/tomthetank46/SwiftFlight.git",
             :tag => "#{s.version}" }

# 7
s.framework = "UIKit"
s.dependency 'SwiftSocket', '~> 2.0.2'

# 8
s.source_files = "SwiftFlight/**/*.{swift}"

# 9
s.resources = "SwiftFlight/**/*.{png,jpeg,jpg,storyboard,xib,xcassets}"

# 10
s.swift_version = "5"

end
