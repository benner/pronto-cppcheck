# frozen_string_literal: true

$LOAD_PATH.push File.expand_path('lib', __dir__)

require 'pronto/cppcheck/version'

Gem::Specification.new do |s|
  s.name = 'pronto-cppcheck'
  s.version = Pronto::CppcheckVersion::VERSION
  s.platform = Gem::Platform::RUBY
  s.authors = ['Nerijus Bendziunas']
  s.email = 'nerijus.bendziunas@gmail.com'
  s.homepage = 'https://github.com/benner/pronto-cppcheck'
  s.summary = <<-SUMMARY
    Pronto runner for cppcheck.
  SUMMARY

  s.licenses = ['Apache-2.0']
  s.required_ruby_version = '>= 3.1.0'

  s.files = Dir.glob('{lib}/**/*') + %w[LICENSE README.md]
  s.extra_rdoc_files = ['LICENSE', 'README.md']
  s.require_paths = ['lib']
  s.requirements << 'cppcheck (in PATH)'

  s.add_dependency('pronto', '< 12.0.0')
  s.add_development_dependency 'bundler', '~> 2.4.3'
  s.add_development_dependency('rake', '~> 12.0')
  s.add_development_dependency('rspec', '~> 3.4')
  s.metadata['rubygems_mfa_required'] = 'true'
end
