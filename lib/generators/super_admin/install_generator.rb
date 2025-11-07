# frozen_string_literal: true

require "rails/generators/base"

module SuperAdmin
  module Generators
    # Generator for installing SuperAdmin in a Rails application.
    # Usage: rails generate super_admin:install
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      desc "Installs SuperAdmin initializer and migrations"

      def copy_initializer_file
        template "super_admin.rb", "config/initializers/super_admin.rb"
      end

      def copy_migrations
        rails_path = File.join(destination_root, "bin/rails")

        unless File.exist?(rails_path)
          say_status :skip, "bin/rails not found; skipping migration installation", :yellow
          return
        end

        in_root do
          run("bin/rails super_admin:install:migrations")
        end
      rescue StandardError => error
        say_status :warning, "Could not run super_admin:install:migrations (#{error.message})", :yellow
      end

      def display_post_install_message
        say "\n"
        say "SuperAdmin has been installed! 🎉", :green
        say "\n"
        say "Next steps:", :yellow
        say "  1. Run migrations:"
        say "     rails db:migrate"
        say "\n"
        say "  2. Mount the engine in config/routes.rb:"
        say "     mount SuperAdmin::Engine => '/super_admin'"
        say "\n"
        say "  3. Generate dashboards for your models:"
        say "     rails generate super_admin:dashboard          # All models"
        say "     rails generate super_admin:dashboard User     # Specific model"
        say "\n"
        say "  4. Configure authentication/authorization in:"
        say "     config/initializers/super_admin.rb"
        say "\n"
        say "  5. Start your server and visit /super_admin"
        say "\n"
        say "✨ Stimulus controllers are automatically registered - no manual setup needed!", :cyan
        say "\n"
      end
    end
  end
end
