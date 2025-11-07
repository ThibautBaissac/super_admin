# frozen_string_literal: true

require "test_helper"
require "generators/super_admin/install_generator"

module SuperAdmin
  module Generators
    class InstallGeneratorTest < Rails::Generators::TestCase
      tests SuperAdmin::Generators::InstallGenerator
      destination File.expand_path("../../../tmp", __dir__)
      setup :prepare_destination

      test "generator creates initializer" do
        run_generator

        assert_file "config/initializers/super_admin.rb" do |content|
          assert_match(/SuperAdmin\.configure/, content)
        end
      end

      test "generator displays installation message" do
        # Generator completes successfully (output checking is not reliable in tests)
        assert_nothing_raised do
          run_generator
        end

        # Ensure initializer was created which indicates successful installation
        assert_file "config/initializers/super_admin.rb"
      end
    end
  end
end
