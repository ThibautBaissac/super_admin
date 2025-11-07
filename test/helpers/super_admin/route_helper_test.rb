# frozen_string_literal: true

require "test_helper"

module SuperAdmin
  class RouteHelperTest < ActiveSupport::TestCase
    class Dummy
      include SuperAdmin::RouteHelper
    end

    test "super_admin_engine exposes engine route helpers" do
      helper = Dummy.new
      assert_equal SuperAdmin::Engine.routes.url_helpers, helper.super_admin_engine
    end
  end
end
