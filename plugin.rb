# name: discourse-admin-statistics-digest
# about: Site digest report for admin
# version: 0.9-beta
# authors: Saiqul Haq
# url: https://github.com/discourse/discourse-admin-statistics-digest


enabled_site_setting :admin_statistics_digest

gem 'rufus-scheduler', '3.2.0'
gem 'sidekiq-scheduler', '2.2.1'

add_admin_route 'admin_statistics_digest.title', 'admin-statistics-digest'

after_initialize do

  load File.expand_path('../../discourse-admin-statistics-digest/lib/admin_statistics_digest.rb', __FILE__)

  module ::AdminStatisticsDigest
    class Engine < ::Rails::Engine
      engine_name ::AdminStatisticsDigest.plugin_name
      isolate_namespace AdminStatisticsDigest
    end
  end

  # libs
  load File.expand_path('../../discourse-admin-statistics-digest/lib/admin_statistics_digest/report.rb', __FILE__)

  # models
  load File.expand_path('../../discourse-admin-statistics-digest/app/models/active_responder_category.rb', __FILE__)
  load File.expand_path('../../discourse-admin-statistics-digest/app/models/email_timeout.rb', __FILE__)

  # mailers
  load File.expand_path('../../discourse-admin-statistics-digest/app/mailers/report_mailer.rb', __FILE__)

  # controllers
  load File.expand_path('../../discourse-admin-statistics-digest/app/controllers/categories_controller.rb', __FILE__)
  load File.expand_path('../../discourse-admin-statistics-digest/app/controllers/report_scheduler_controller.rb', __FILE__)

  # jobs
  if Rails.env.development? || (defined?(Rails::Server) || defined?(Unicorn) || defined?(Puma))
    require 'sidekiq/scheduler'


    load File.expand_path('../../discourse-admin-statistics-digest/app/jobs/admin_statistics_digest.rb', __FILE__)

    Sidekiq.configure_server do |config|

      Sidekiq::Scheduler.enabled = true
      Sidekiq::Scheduler.dynamic = true

      config.on(:startup) do
        AdminStatisticsDigest.reload_digest_report_schedule
      end

    end
  end


  AdminStatisticsDigest::Engine.routes.draw do
    root to: 'categories#root'
    get 'categories', to: 'categories#index'
    put 'categories/update', to: 'categories#update'
    get 'report-scheduler/preview', to: 'report_scheduler#preview'
    get 'report-scheduler/timeout', to: 'report_scheduler#get_timeout'
    put 'report-scheduler/timeout', to: 'report_scheduler#set_timeout'
  end

  Discourse::Application.routes.append do
    mount ::AdminStatisticsDigest::Engine, at: '/admin/plugins/admin-statistics-digest', constraints: AdminConstraint.new
  end

end
