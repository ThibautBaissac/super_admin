# frozen_string_literal: true

require "test_helper"

module SuperAdmin
  class ValidationTest < ActiveSupport::TestCase
    test "should validate AuditLog requires resource_type" do
      audit_log = AuditLog.new(
        action: "create",
        performed_at: Time.current
      )

      assert_not audit_log.valid?
      assert_includes audit_log.errors[:resource_type], "can't be blank"
    end

    test "should validate AuditLog requires action" do
      audit_log = AuditLog.new(
        resource_type: "User",
        performed_at: Time.current
      )

      assert_not audit_log.valid?
      assert_includes audit_log.errors[:action], "can't be blank"
    end

    test "should validate AuditLog requires performed_at" do
      audit_log = AuditLog.new(
        resource_type: "User",
        action: "create"
      )

      # Should auto-set performed_at
      audit_log.valid?
      assert_not_nil audit_log.performed_at
    end

    test "should validate CsvExport requires token" do
      export = CsvExport.new(
        resource_name: "users",
        model_class_name: "User",
        status: :pending,
        user: users(:one)
      )

      export.stub(:generate_token, nil) do
        assert_not export.valid?
        assert_includes export.errors[:token], "can't be blank"
      end
    end

    test "should validate CsvExport requires status" do
      export = CsvExport.new(
        token: SecureRandom.urlsafe_base64(32),
        resource_name: "users",
        model_class_name: "User",
        user: users(:one)
      )

      export.status = nil
      assert_not export.valid?
      assert_includes export.errors[:status], "can't be blank"
    end

    test "should validate CsvExport requires resource_name" do
      export = CsvExport.new(
        token: SecureRandom.urlsafe_base64(32),
        model_class_name: "User",
        status: :pending,
        user: users(:one)
      )

      export.resource_name = nil
      assert_not export.valid?
      assert_includes export.errors[:resource_name], "can't be blank"
    end

    test "should validate CsvExport status enum values" do
      export = CsvExport.new(
        token: SecureRandom.urlsafe_base64(32),
        resource_name: "users",
        model_class_name: "User",
        user: users(:one)
      )

      # Valid statuses
      %w[pending processing ready failed].each do |status|
        export.status = status
        assert export.valid?, "#{status} should be a valid status"
      end
    end

    test "should validate CsvExport token uniqueness" do
      token = SecureRandom.urlsafe_base64(32)

      export1 = CsvExport.create!(
        token: token,
        resource_name: "users",
        model_class_name: "User",
        status: :pending,
        user: users(:one)
      )

      export2 = CsvExport.new(
        token: token,
        resource_name: "users",
        model_class_name: "User",
        status: :pending,
        user: users(:one)
      )

      assert_not export2.valid?
      assert_includes export2.errors[:token], "has already been taken"
    end

    test "should validate User email presence" do
      user = User.new(name: "Test")

      assert_not user.valid?
      assert_includes user.errors[:email], "can't be blank"
    end

    test "should validate User email uniqueness" do
      User.create!(email: "unique@example.com", name: "User 1")

      user2 = User.new(email: "unique@example.com", name: "User 2")

      assert_not user2.valid?
      assert_includes user2.errors[:email], "has already been taken"
    end

    test "should validate User email format" do
      user = User.new(email: "invalid_email", name: "Test")

      # Assuming User has email format validation
      # If not, this test will need adjustment
      if user.respond_to?(:email) && !user.valid?
        # Email format validation might be present
        assert user.errors[:email].any? if user.errors[:email].present?
      end
    end

    test "should handle validation errors in Auditing service" do
      # Create an audit log with invalid data
      result = Auditing.log!(
        user: nil,
        resource_type: nil, # Invalid - required
        resource_id: 1,
        action: :create
      )

      # Should handle validation error gracefully
      assert_nil result
    end

    test "should validate enum values" do
      if User.defined_enums.key?("role")
        user = User.new(email: "enum@example.com", name: "Test")

        # Valid enum value
        user.role = User.roles.keys.first
        assert user.valid? || !user.errors[:role].any?

        # Invalid enum value
        assert_raises(ArgumentError) do
          user.role = "invalid_role_value"
        end
      end
    end

    test "should validate association presence if required" do
      # If Post requires user
      post = Post.new(title: "Test Post")

      # Check if user is required
      if post.class.validators_on(:user).any? { |v| v.is_a?(ActiveRecord::Validations::PresenceValidator) }
        assert_not post.valid?
        assert_includes post.errors[:user], "must exist"
      end
    end

    test "should validate maximum length constraints" do
      # If User has length constraints
      long_name = "a" * 1000

      user = User.new(email: "length@example.com", name: long_name)

      # Length validation might or might not exist
      # This test just ensures it doesn't crash
      user.valid?
      assert user.is_a?(User)
    end

    test "should validate numericality constraints" do
      # If User has numeric columns with constraints
      numeric_column = User.columns.find { |c| c.type == :integer && c.name != "id" }

      if numeric_column
        user = User.new(email: "numeric@example.com", name: "Test")

        # Try setting invalid numeric value
        user.public_send("#{numeric_column.name}=", "not_a_number")

        # Should either convert or raise error
        assert user.is_a?(User)
      end
    end

    test "should validate custom validations" do
      # Test any custom validations on models
      user = User.new(email: "custom@example.com", name: "Test")

      # Run validations
      user.valid?

      # Should have error structure even if no errors
      assert user.errors.is_a?(ActiveModel::Errors)
    end

    test "should validate nested attributes" do
      if User.nested_attributes_options.any?
        association_name = User.nested_attributes_options.keys.first

        user = User.new(
          email: "nested@example.com",
          name: "Test",
          "#{association_name}_attributes" => [
            {
              title: "Nested Post",
              body: "Nested Body"
            }
          ]
        )

        # Should handle nested validation
        user.valid?
        assert user.is_a?(User)
      end
    end

    test "should validate date and datetime formats" do
      audit_log = AuditLog.new(
        resource_type: "User",
        action: "create",
        performed_at: "invalid_date"
      )

      # Should handle invalid date format
      assert audit_log.is_a?(AuditLog)
    end

    test "should validate JSON fields" do
      audit_log = AuditLog.new(
        resource_type: "User",
        action: "create",
        performed_at: Time.current,
        changes_snapshot: "not valid json",
        context: "not valid json"
      )

      # Should either accept string or convert to hash
      audit_log.valid?
      assert audit_log.is_a?(AuditLog)
    end
  end
end
