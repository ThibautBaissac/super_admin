# frozen_string_literal: true

require "rails/generators/base"
require "super_admin/dashboard_creator"

module SuperAdmin
  module Generators
    # Generator for creating SuperAdmin dashboard files.
    # Usage: rails generate super_admin:dashboard [ModelName]
    class DashboardGenerator < Rails::Generators::Base
      desc "Generates a SuperAdmin dashboard for a specific model or all models"

      argument :model_name, type: :string, required: false,
               desc: "Name of the model (optional, generates for all models if omitted)"

      def generate_dashboards
        # Wrap the Thor shell to provide a puts method
        generator = self
        stdout_wrapper = Object.new
        stdout_wrapper.define_singleton_method(:puts) do |message = ""|
          generator.say(message)
        end

        result = SuperAdmin::DashboardCreator.call(
          model_name: model_name,
          stdout: stdout_wrapper
        )

        if result[:generated].empty? && result[:skipped].empty?
          say "\nNo dashboards were created. Make sure you have ActiveRecord models in your application.", :yellow
        end
      end

      def display_next_steps
        return if @_already_displayed_next_steps

        say "\n"
        say "Dashboard generation complete! 🎉", :green
        say "\n"
        say "Next steps:", :yellow
        say "  1. Review generated dashboards in app/dashboards/super_admin/"
        say "  2. Customize attributes and display logic as needed"
        say "  3. Visit #{SuperAdmin::Engine.routes.url_helpers.root_path rescue '/admin'} to see your admin interface"
        say "\n"

        @_already_displayed_next_steps = true
      end
    end
  end
end
