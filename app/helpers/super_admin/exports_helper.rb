# frozen_string_literal: true

module SuperAdmin
  module ExportsHelper
    BADGE_CLASSES = {
      "pending" => "bg-yellow-100 text-yellow-800",
      "processing" => "bg-blue-100 text-blue-800",
      "ready" => "bg-green-100 text-green-800",
      "failed" => "bg-red-100 text-red-800"
    }.freeze

    def export_badge_classes(export)
      BADGE_CLASSES.fetch(export.status, "bg-gray-100 text-gray-800")
    end
  end
end
