#!/usr/bin/env gem build

$LOAD_PATH.unshift(File.expand_path('../lib', __FILE__))

require 'terminal.com'

Gem::Specification.new do |s|
  s.name = 'terminal.com'
  s.version = Terminal::VERSION
  s.date = Date.today.to_s
  s.authors = ['James C Russell']
  s.homepage = 'http://github.com/botanicus/terminal.com'
  s.summary = "The official Terminal.com Ruby + CLI client"
  s.description = "#{s.summary}."
  s.email = 'james@cloudlabs.io'
  s.files = ['README.md', 'bin/terminal.com', 'docs/help.txt', *Dir.glob('**/*.rb')]
  s.license = 'MIT'
  s.require_paths = ['lib']
  s.executables = 'terminal.com'

  # This is only for bin/terminal.com. With this,
  # you get syntax JSON highlighting on console.
  s.add_development_dependency 'coderay', '~> 1'
end
