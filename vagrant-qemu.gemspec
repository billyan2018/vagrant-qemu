$:.unshift File.expand_path("../lib", __FILE__)
require "vagrant-qemu/version"

Gem::Specification.new do |s|
  s.name          = "vagrant-qemu"
  s.version       = VagrantPlugins::Qemu::VERSION
  s.platform      = Gem::Platform::RUBY
  s.authors       = ["Bill Yan" ]
  s.email         = [ "libin.bill.yan@gmail.com" ]
  s.homepage      = "https://destructuring.org/vagrant-qemu"
  s.summary       = "Enables Vagrant to manage machines using qemu"
  s.description   = "Enables Vagrant to manage machines using qemu"

  s.required_rubygems_version = ">= 2.0.0"
  s.rubyforge_project         = "vagrant-qemu"

  s.files         = Dir["lib/**/*"] + Dir["locales/**/*"]
  s.require_path  = 'lib'
end
