# Development environment configuration
# This file contains settings for the development environment

Rails.application.configure do
  config.after_initialize do
    Bullet.enable        = true
    Bullet.alert         = true
    Bullet.bullet_logger = true
    Bullet.console       = true
    Bullet.rails_logger  = true
    Bullet.add_footer    = true
  end

  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports and disable caching.
  config.consider_all_requests_local = true
  config.action_controller.perform_caching = true

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = false

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Assets are disabled in API-only mode
  # config.assets.debug = true
  # config.assets.quiet = true

  # Raises error for missing translations.
  # config.action_view.raise_on_missing_translations = true

  # Use a file watcher to asynchronously detect changes in source code,
  # routes, and locales, and reload the application when something changes.
  # config.file_watcher = ActiveSupport::FileUpdateChecker

  # Enable detailed logging for debugging
  config.log_level = :debug

  # Enable SQL logging for debugging N+1 queries
  ActiveRecord::Base.logger = Logger.new(STDOUT)

  config.cache_store = :memory_store
end 