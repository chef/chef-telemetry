source "https://rubygems.org"

# Specify your gem's dependencies in chef-telemetry.gemspec
gemspec

group :debug do
  gem "pry"
  gem "pry-byebug"
  gem "pry-stack_explorer"
end

group :test do
  gem "parallel", "< 1.20" # remove this pin/dep when we drop ruby < 2.4
  gem "chefstyle", "1.5.7"
  gem "rake"
  gem "rspec", "~> 3.0"
end

group :docs do
  gem "github-markup"
  gem "redcarpet"
  gem "yard"
end
