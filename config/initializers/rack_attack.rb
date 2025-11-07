# frozen_string_literal: true

# Configure Rack::Attack for SuperAdmin endpoints
# This protects against common attacks like brute force, DoS, and abuse

module SuperAdmin
  class RackAttackConfiguration
    class << self
      def configure
        return unless defined?(Rack::Attack)

        configure_throttles
        configure_blocklists
        configure_safelists
        configure_tracking
      end

      private

      def configure_throttles
        # Throttle searches to prevent DoS
        Rack::Attack.throttle("super_admin/searches/ip", limit: 30, period: 60) do |req|
          if req.path.start_with?("/super_admin") && (req.get? || req.post?) && req.path.include?("search")
            req.ip
          end
        end

        # Throttle association search API (more generous as it's used heavily in forms)
        Rack::Attack.throttle("super_admin/api/associations/ip", limit: 100, period: 60) do |req|
          if req.path == "/super_admin/associations/search" && req.get?
            req.ip
          end
        end

        # Throttle CSV exports to prevent abuse
        Rack::Attack.throttle("super_admin/exports/ip", limit: 5, period: 300) do |req|
          if req.path.start_with?("/super_admin") && req.post? && req.path.include?("export")
            req.ip
          end
        end

        # Throttle bulk operations (more restrictive)
        Rack::Attack.throttle("super_admin/bulk/ip", limit: 10, period: 60) do |req|
          if req.path.match?(%r{/super_admin/.+/bulk}) && req.post?
            req.ip
          end
        end

        # Throttle write operations (create/update/delete)
        Rack::Attack.throttle("super_admin/writes/ip", limit: 60, period: 60) do |req|
          if req.path.start_with?("/super_admin") && (req.post? || req.patch? || req.put? || req.delete?)
            req.ip
          end
        end

        # Global throttle for all SuperAdmin requests
        Rack::Attack.throttle("super_admin/global/ip", limit: 300, period: 60) do |req|
          if req.path.start_with?("/super_admin")
            req.ip
          end
        end
      end

      def configure_blocklists
        # Block requests from known bad actors (can be configured via environment)
        Rack::Attack.blocklist("super_admin/blocked_ips") do |req|
          if req.path.start_with?("/super_admin")
            blocked_ips = ENV.fetch("SUPER_ADMIN_BLOCKED_IPS", "").split(",").map(&:strip)
            blocked_ips.include?(req.ip)
          end
        end

        # Block requests with suspicious patterns in query params
        Rack::Attack.blocklist("super_admin/sql_injection_attempts") do |req|
          if req.path.start_with?("/super_admin")
            query_string = req.query_string.to_s.downcase
            # Detect common SQL injection patterns
            query_string.match?(/(\bunion\b|\bselect\b|\binsert\b|\bupdate\b|\bdelete\b|\bdrop\b).*(\bfrom\b|\binto\b|\btable\b)/)
          end
        end
      end

      def configure_safelists
        # Safelist requests from localhost in development
        Rack::Attack.safelist("super_admin/localhost") do |req|
          if req.path.start_with?("/super_admin")
            Rails.env.development? && [ "127.0.0.1", "::1" ].include?(req.ip)
          end
        end

        # Allow configurable safelist via environment
        Rack::Attack.safelist("super_admin/safelisted_ips") do |req|
          if req.path.start_with?("/super_admin")
            safe_ips = ENV.fetch("SUPER_ADMIN_SAFE_IPS", "").split(",").map(&:strip)
            safe_ips.include?(req.ip)
          end
        end
      end

      def configure_tracking
        # Track requests for monitoring (optional, requires Rails cache)
        Rack::Attack.track("super_admin/requests") do |req|
          req.path.start_with?("/super_admin")
        end
      end
    end
  end
end

# Auto-configure if Rack::Attack is available
if defined?(Rack::Attack)
  SuperAdmin::RackAttackConfiguration.configure

  # Custom response for throttled requests
  Rack::Attack.throttled_responder = lambda do |req|
    match_data = req.env["rack.attack.match_data"]
    now = match_data[:epoch_time]

    headers = {
      "Content-Type" => "application/json",
      "X-RateLimit-Limit" => match_data[:limit].to_s,
      "X-RateLimit-Remaining" => "0",
      "X-RateLimit-Reset" => (now + (match_data[:period] - now % match_data[:period])).to_s
    }

    body = {
      error: "Rate limit exceeded",
      message: "Too many requests. Please try again later.",
      retry_after: match_data[:period] - now % match_data[:period]
    }

    [ 429, headers, [ body.to_json ] ]
  end
end
