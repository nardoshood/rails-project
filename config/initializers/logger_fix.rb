# Fix for Logger compatibility issue between Ruby 3.2.2 and Rails 7.0.8.7
require 'logger'

module ActiveSupport
  module LoggerThreadSafeLevel
    # Ensure Logger is available
    Logger = ::Logger unless defined?(Logger)
  end
end