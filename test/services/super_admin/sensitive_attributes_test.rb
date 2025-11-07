# frozen_string_literal: true

require "test_helper"

module SuperAdmin
  class SensitiveAttributesTest < ActiveSupport::TestCase
    test "should identify password fields as sensitive" do
      assert SensitiveAttributes.sensitive?(:password)
      assert SensitiveAttributes.sensitive?(:password_digest)
      assert SensitiveAttributes.sensitive?(:password_confirmation)
    end

    test "should identify token fields as sensitive" do
      assert SensitiveAttributes.sensitive?(:api_token)
      assert SensitiveAttributes.sensitive?(:auth_token)
      assert SensitiveAttributes.sensitive?(:reset_password_token)
    end

    test "should identify secret fields as sensitive" do
      assert SensitiveAttributes.sensitive?(:secret_key)
      assert SensitiveAttributes.sensitive?(:client_secret)
    end

    test "should not identify normal fields as sensitive" do
      assert_not SensitiveAttributes.sensitive?(:name)
      assert_not SensitiveAttributes.sensitive?(:email)
      assert_not SensitiveAttributes.sensitive?(:title)
    end

    test "should handle string and symbol attribute names" do
      assert SensitiveAttributes.sensitive?("password")
      assert SensitiveAttributes.sensitive?(:password)
    end

    test "should be case insensitive" do
      assert SensitiveAttributes.sensitive?(:PASSWORD)
      assert SensitiveAttributes.sensitive?("Password")
    end

    test "should include additional configured sensitive attributes" do
      begin
        SuperAdmin.configure do |config|
          config.additional_sensitive_attributes = [ :custom_secret ]
        end

        assert SensitiveAttributes.sensitive?(:custom_secret)
      ensure
        SuperAdmin.configure do |config|
          config.additional_sensitive_attributes = []
        end
      end
    end

    test "should filter sensitive data from hash" do
      data = {
        name: "John",
        email: "john@example.com",
        password: "secret123",
        api_token: "abc123"
      }

      filtered = SensitiveAttributes.filter(data)

      assert_equal "John", filtered[:name]
      assert_equal "john@example.com", filtered[:email]
      assert_equal "[FILTERED]", filtered[:password]
      assert_equal "[FILTERED]", filtered[:api_token]
    end

    test "should handle nested hashes" do
      data = {
        user: {
          name: "John",
          password: "secret"
        }
      }

      filtered = SensitiveAttributes.filter(data)

      assert_equal "John", filtered[:user][:name]
      assert_equal "[FILTERED]", filtered[:user][:password]
    end
  end
end
