source "https://rubygems.org"

# Specify your gem's dependencies in chef-telemetry.gemspec
gemspec

group :debug do
  gem "pry"
  gem "pry-byebug"
  gem "pry-stack_explorer"
end

group :test do
  gem "chefstyle", "1.7.4"
  gem "rake"
  gem "rspec", "~> 3.0"
end

group :docs do
  gem "github-markup"
  gem "redcarpet"
  gem "yard"
end

if Gem.ruby_version < Gem::Version.new("2.6")
  # 16.7.23 required ruby 2.6+
  gem "chef-utils", "< 16.7.23" # TODO: remove when we drop ruby 2.5
end
