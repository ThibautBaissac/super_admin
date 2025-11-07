require "super_admin/dashboard_creator"
require "super_admin/install_task"

namespace :super_admin do
  desc "Install SuperAdmin (use 'rails generate super_admin:install' instead)"
  task install: :environment do
    puts "⚠️  This rake task is deprecated. Please use the generator instead:"
    puts "   rails generate super_admin:install"
    puts "\nRunning generator..."
    Rails::Generators.invoke("super_admin:install")
  rescue StandardError => e
    abort "SuperAdmin install failed: #{e.message}"
  end

  namespace :install do
    desc "Copy migrations from SuperAdmin to application"
    task :migrations do
      SuperAdmin::InstallTask.new.send(:copy_migrations)
    end
  end

  namespace :dashboards do
    desc "Generate SuperAdmin dashboards (use 'rails generate super_admin:dashboard' instead)"
      task :generate, [ :model_name ] => :environment do |_task, args|
        model_name = args[:model_name] || ENV["MODEL"]
        puts "⚠️  This rake task is deprecated. Please use the generator instead:"
        if model_name
          puts "   rails generate super_admin:dashboard #{model_name}"
        else
          puts "   rails generate super_admin:dashboard"
        end
        puts "\nRunning generator..."
        Rails::Generators.invoke("super_admin:dashboard", [ model_name ].compact)
    rescue ArgumentError => e
      abort e.message
    end
  end
end
