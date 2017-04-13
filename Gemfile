source 'https://rubygems.org'

# Specify your gem's dependencies in mini_mime.gemspec
gemspec

gem 'mime-types', '~> 3' if RUBY_VERSION > '2'
gem 'memory_profiler' if RUBY_VERSION >= '2.1.0'
gem 'benchmark-ips'
if RUBY_PLATFORM != 'java' && RUBY_VERSION > '1.9'
  gem 'micro_mime', :git => 'https://github.com/stereobooster/micro_mime.git'
end
