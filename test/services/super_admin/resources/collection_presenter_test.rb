# frozen_string_literal: true

require "test_helper"

module SuperAdmin
  module Resources
    class CollectionPresenterTest < ActiveSupport::TestCase
      setup do
        User.delete_all

        @alice = User.create!(email: "alice@example.com", name: "Alice", role: :user)
        @bob = User.create!(email: "bob@example.com", name: "Bob", role: :user)
        @carol = User.create!(email: "carol@example.com", name: "Carol", role: :user)
        @admin = User.create!(email: "admin@example.com", name: "Admin", role: :admin)

        @context = Context.new("users")
      end

      test "exposes metadata from context" do
        presenter = CollectionPresenter.new(context: @context, params: build_params)

        assert_equal User, presenter.model_class
        assert_equal "users", presenter.resource_param
      end

      test "applies search to scope" do
        presenter = CollectionPresenter.new(context: @context, params: build_params(search: "alice"))

        assert_equal [ @alice.email ], presenter.scope.pluck(:email)
      end

      test "sanitizes and applies filters" do
        params = build_params(filters: { role_equals: "admin", malicious: "1" })
        presenter = CollectionPresenter.new(context: @context, params: params)

        assert_equal({ "role_equals" => "admin" }, presenter.filter_params)
        assert_equal [ @admin.email ], presenter.scope.pluck(:email)
      end

      test "applies sorting directives" do
        presenter = CollectionPresenter.new(context: @context, params: build_params(sort: "name", direction: "asc"))

        assert_equal %w[Admin Alice Bob Carol], presenter.scope.pluck(:name)
      end

      test "preserves meaningful params" do
        params = build_params(search: "Ali", direction: "desc", filters: { role_equals: "admin" })
        presenter = CollectionPresenter.new(context: @context, params: params)

        assert_equal({ search: "Ali", direction: "desc", filters: { "role_equals" => "admin" } }, presenter.preserved_params)
      end

      test "provides filter definitions" do
        presenter = CollectionPresenter.new(context: @context, params: build_params)

        attributes = presenter.filter_definitions.map(&:attribute)
        assert_includes attributes, "role"
      end

      test "queues exports with sanitized state" do
        params = build_params(search: "ali", sort: "name", filters: { role_equals: "admin" })
        presenter = CollectionPresenter.new(context: @context, params: params)
        captured = nil

        SuperAdmin::CsvExportCreator.stub(:call, ->(**args) { captured = args; :export }) do
          presenter.queue_export!(@admin, %w[email name])
        end

        assert_equal @admin, captured[:user]
        assert_equal User, captured[:model_class]
        assert_equal "users", captured[:resource]
        assert_equal "ali", captured[:search]
        assert_equal "name", captured[:sort]
        assert_nil captured[:direction]
        assert_equal({ "role_equals" => "admin" }, captured[:filters])
        assert_equal %w[email name], captured[:attributes]
      end

      private

      def build_params(overrides = {})
        ActionController::Parameters.new(overrides)
      end
    end
  end
end
