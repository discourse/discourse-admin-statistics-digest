require_dependency 'email/message_builder'

module ::AdminStatisticsDigest
  module Mailer

    class StatisticsMailer < ActionMailer::Base
      include ::Email::BuildEmailHelper
      include Rails.application.routes.url_helpers

      helper do
        def logo_url
          logo_url = SiteSetting.digest_logo_url
          logo_url = SiteSetting.logo_url if logo_url.blank? || logo_url =~ /\.svg$/i

          return nil if logo_url.blank? || logo_url =~ /\.svg$/i
          if logo_url !~ /http(s)?\:\/\//
            logo_url = "#{Discourse.base_url}#{logo_url}"
          end
          logo_url
        end
      end

      def self.mailer_name
        'admin_statistics_mailer'
      end

      append_view_path(Rails.root.join('plugins', 'discourse-admin-statistics-digest', 'app', 'views').to_s)

      # new_active_users: {}
      # top_non_staff: {}
      def digest(new_active_users: {}, top_non_staff_users: {}, limit: 5)
        return unless SiteSetting.contact_email.present?

        report = AdminStatisticsDigest::Report.new

        @new_active_users = report.new_active_users({ limit: limit }.merge(new_active_users))
        @top_non_staff_users = report.top_non_staff_users({ limit: limit, include_staff: false }.merge(top_non_staff_users))

        build_email( SiteSetting.contact_email,
              subject: 'Report for ...',
              from: 'admin@stie.com'
        )

      end
    end

  end
end
