# name: discourse-admin-statistics-digest
# about: Site digest report for admin
# version: 0.9-beta
# authors: Saiqul Haq
# url: https://github.com/discourse/discourse-admin-statistics-digest


enabled_site_setting :admin_statistics_digest_enabled

PLUGIN_NAME = 'admin-statistics-digest'.freeze

add_admin_route 'admin_statistics_digest.title', 'admin-statistics-digest'

after_initialize do

  require_dependency 'admin_constraint'

  module ::AdminStatisticsDigest
    class Engine < ::Rails::Engine
      engine_name PLUGIN_NAME
      isolate_namespace AdminStatisticsDigest
    end
  end

  [
    '../../discourse-admin-statistics-digest/lib/admin_statistics_digest/report.rb',
    '../../discourse-admin-statistics-digest/app/mailers/report_mailer.rb',
    '../../discourse-admin-statistics-digest/app/jobs/admin_statistics_digest.rb'
  ].each { |path| load File.expand_path(path, __FILE__ )}

  require_dependency 'application_controller'
  class AdminStatisticsDigest::AdminStatisticsDigestController < ::ApplicationController
    def index
    end

    def preview
      # Send the preview for the current month. The month could be added as a parameter.
      AdminStatisticsDigest::ReportMailer.digest(0).deliver_now
      render json: { success: true }
    end
  end

  AdminStatisticsDigest::Engine.routes.draw do
    root to: 'admin_statistics_digest#index', constraints: AdminConstraint.new
    get 'preview', to: 'admin_statistics_digest#preview', constraints: AdminConstraint.new
  end

  Discourse::Application.routes.append do
    mount ::AdminStatisticsDigest::Engine, at: '/admin/plugins/admin-statistics-digest', constraints: AdminConstraint.new
  end

end
