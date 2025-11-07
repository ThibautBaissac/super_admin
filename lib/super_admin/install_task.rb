# frozen_string_literal: true

require "fileutils"
require "pathname"

module SuperAdmin
  # Handles bootstrapping host applications with required SuperAdmin assets.
  class InstallTask
    INITIALIZER_PATH = "config/initializers/super_admin.rb"

    def self.call(stdout: $stdout)
      new(stdout:).call
    end

    def initialize(stdout: $stdout)
      @stdout = stdout
      @engine_root = Pathname.new(SuperAdmin::Engine.root)
      @app_root = Pathname.new(Rails.root)
    end

    def call
      copy_initializer
      copy_migrations
      stdout.puts "SuperAdmin installation complete."
    end

    # Public method for copying migrations (used by rake task)
    def copy_migrations
      migration_files.each do |source_path|
        copy_migration(source_path)
      end
    end

    private

    attr_reader :stdout, :engine_root, :app_root

    def copy_initializer
      target = app_root.join(INITIALIZER_PATH)
      if target.exist?
        stdout.puts "Initializer already exists at #{relative_to_app(target)} (skipping)."
        return
      end

      source = engine_root.join(INITIALIZER_PATH)
      FileUtils.mkdir_p(target.dirname)
      FileUtils.cp(source, target)
      stdout.puts "Initializer copied to #{relative_to_app(target)}."
    end

    def migration_files
      # Dir[] does not guarantee order, so we must sort to preserve migration sequence.
      # We filter to only include files starting with a timestamp (e.g., 20240101000001_)
      # to avoid copying non-migration files like super_admin.rb
      Dir[engine_root.join("lib", "generators", "super_admin", "templates", "*.rb")]
        .select { |f| File.basename(f) =~ /^\d+_/ }
        .sort
    end

    def copy_migration(source_path)
      basename = File.basename(source_path).sub(/^\d+_/, "")

      if migration_exists?(basename)
        stdout.puts "Migration #{basename} already present (skipping)."
        return
      end

      timestamp = next_migration_timestamp
      target = app_root.join("db", "migrate", "#{timestamp}_#{basename}")
      FileUtils.mkdir_p(target.dirname)
      FileUtils.cp(source_path, target)
      stdout.puts "Migration created at #{relative_to_app(target)}."
    end

    def migration_exists?(basename)
      Dir[app_root.join("db", "migrate", "*_#{basename}").to_s].any?
    end

    def next_migration_timestamp
      now = Time.now.utc.strftime("%Y%m%d%H%M%S").to_i
      @migration_counter ||= begin
        existing = Dir[app_root.join("db", "migrate", "*.rb").to_s]
        existing.map { |path| File.basename(path).split("_", 2).first.to_i }.max || 0
      end

      @migration_counter = [ @migration_counter + 1, now ].max
      format("%014d", @migration_counter)
    end

    def relative_to_app(path)
      path.relative_path_from(app_root)
    rescue ArgumentError
      path
    end
  end
end
