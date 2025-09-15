source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "3.2.2"

# Rails framework
gem "rails", "~> 7.0.0"
# Use sqlite3 as the database for Active Record
gem "sqlite3", "~> 1.4"
# Use Puma as the app server
gem "puma", "~> 5.0"
# Build JSON APIs with ease
gem "jbuilder"
# Use for N+1 queries
gem 'bullet', group: 'development'
# Use Redis adapter to run Action Cable in production
# gem "redis", "~> 4.0"
# Use Active Model has_secure_password
# gem "bcrypt", "~> 3.1.7"

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
# gem "image_processing", "~> 1.2"

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# For caching (Task 2.3 requirement) - Using Rails built-in caching instead
# gem "actionpack-action_caching" # Removed - not compatible with Rails 7

# For pagination (Task 3.1 requirement)
gem "kaminari"

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri mingw x64_mingw ]
  # Use RSpec for testing
  gem "rspec-rails"
  # Use FactoryBot for test data
  gem "factory_bot_rails"
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"
  # Add speed badges [https://github.com/MiniProfiler/rack-mini-profiler]
  # gem "rack-mini-profiler"

  # Speed up commands on slow machines / big apps [https://github.com/rails/spring]
  # gem "spring"
end

group :test do
  gem "rails-controller-testing"
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ mingw mswin x64_mingw jruby ]

# Uncomment to use Active Record encryption
# gem "lockbox"

# Uncomment to use Active Model encryption
# gem "activerecord-encryption"

# Uncomment to use the full version of the React Developer Tools
# gem "react-rails"

# Uncomment to use the build script from Create React App
# gem "jsbundling-rails"

# Uncomment to use the JavaScript bundler
# gem "importmap-rails"

# Uncomment to use the CSS bundler
# gem "sassc-rails"

# Uncomment to use the JavaScript bundler
# gem "esbuild-rails"

# Uncomment to use the CSS bundler
# gem "tailwindcss-rails" 