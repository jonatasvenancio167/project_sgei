require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module ProjectSgei
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.0

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

    # UI is entirely pt-BR; locale files are organized in subdirectories
    # (models/, views/, notifications/, mailers/) per docs/design_patters.md.
    # Rails/ActiveModel/Devise built-in translations (date formats,
    # to_sentence connectors, default error/flash messages) come from the
    # rails-i18n and devise-i18n gems, which ship their own pt-BR locale files.
    config.i18n.load_path += Dir[Rails.root.join("config", "locales", "**", "*.yml")]
    config.i18n.default_locale = :"pt-BR"
  end
end
