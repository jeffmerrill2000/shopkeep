require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
# require "action_mailbox/engine"
# require "action_text/engine"
require "action_view/railtie"
# require "action_cable/engine"
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Shopkeep
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    config.autoload_paths << Rails.root.join("app/domains")
    config.eager_load_paths << Rails.root.join("app/domains")

    config.active_job.queue_adapter = :sidekiq
    # Image variants arrive with the catalog milestone. Until then, skip the vips/ImageMagick requirement.
    config.active_storage.variant_processor = :disabled
    config.cache_store = :redis_cache_store, { url: ENV.fetch("REDIS_URL", "redis://127.0.0.1:6379/0") }

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Only loads a smaller set of middleware suitable for API only apps.
    # Cookie sessions are required for authentication and CSRF. See ADR 0004.
    config.api_only = true
    config.middleware.use ActionDispatch::Cookies
    config.middleware.use ActionDispatch::Session::CookieStore,
      key: "_shopkeep_session",
      same_site: :lax,
      httponly: true,
      secure: Rails.env.production?
    config.middleware.use Rack::Attack

    initializer "shopkeep.domain_collapse" do
      %w[identity tenancy audit catalog inventory pricing cart customers orders checkout fulfillment reports].each do |name|
        Rails.autoloaders.main.collapse(Rails.root.join("app/domains/#{name}"))
      end
    end
  end
end
