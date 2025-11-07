# frozen_string_literal: true

require "test_helper"

module SuperAdmin
  class ApplicationControllerTest < ActionController::TestCase
    class DummyController < SuperAdmin::ApplicationController
      def index
        head :ok
      end

      private

      def symbol_user
        "symbol-user"
      end
    end

    tests DummyController

    setup do
      SuperAdmin.reset_configuration!
      @request = ActionDispatch::TestRequest.create
      @response = ActionDispatch::TestResponse.new
    end

    teardown do
      SuperAdmin.reset_configuration!
    end

    test "current_user returns value from proc strategy" do
      user = users(:one)
      SuperAdmin.configure { |config| config.current_user_method = -> { user } }

      assert_equal user, @controller.send(:current_user)
    end

    test "current_user falls back to strategy binding receiver" do
      resolver = Class.new do
        attr_reader :value

        def initialize
          @value = "fallback-user"
        end

        def resolve(receiver)
          return nil if receiver.is_a?(SuperAdmin::ApplicationController)

          value
        end
      end.new

      SuperAdmin.configure { |config| config.current_user_method = resolver.method(:resolve).to_proc }

      assert_equal "fallback-user", @controller.send(:current_user)
    end

    test "current_user uses symbol strategy without recursion" do
      SuperAdmin.configure { |config| config.current_user_method = :symbol_user }

      assert_equal "symbol-user", @controller.send(:current_user)
    end

    test "current_user handles self-referential strategy safely" do
      SuperAdmin.configure { |config| config.current_user_method = :current_user }

      assert_nil @controller.send(:current_user)
    end
  end
end
