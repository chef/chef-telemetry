source "https://rubygems.org"

git_source(:github) { |repo_name| "https://github.com/#{repo_name}" }

group :development, :test do
  gem "chefstyle"
end

# Specify your gem's dependencies in chef-telemetry.gemspec
gemspec
