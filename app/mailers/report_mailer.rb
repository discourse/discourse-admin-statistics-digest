class AdminStatisticsDigest::ReportMailer < ActionMailer::Base

  include Rails.application.routes.url_helpers
  include ApplicationHelper
  helper :application
  default charset: 'UTF-8'

  helper_method :dir_for_locale, :logo_url, :header_color, :header_bgcolor, :anchor_color,
                :bg_color, :text_color, :highlight_bgcolor, :highlight_color, :body_bgcolor,
                :body_color, :report_date, :digest_title, :spacer_color, :table_border_style,
                :site_link, :statistics_digest_link, :superscript

  append_view_path Rails.root.join('plugins', 'discourse-admin-statistics-digest', 'app', 'views')
  default from: SiteSetting.notification_email

  def digest(months_ago)
    active_users_for_period = active_users(months_ago)
    inactive_users_for_period = all_users - active_users_for_period
    posts_created_for_period = posts_created(months_ago, 'regular', false)
    dau_for_period = daily_active_users(months_ago)
    mau_for_period = active_users_for_period
    health_for_period = health(dau_for_period, mau_for_period)
    subject = digest_title(months_ago)

    header_metadata = [
      {key: 'statistics_digest.active_users', value: active_users_for_period},
      {key: 'statistics_digest.posts_created', value: posts_created_for_period},
      {key: 'statistics_digest.posts_read', value: posts_read(months_ago)}
    ]

    health_data = {
      title_key: 'statistics_digest.community_health_title',
      fields: [
        {key: 'statistics_digest.daily_active_users', value: dau_for_period, description_index: 1},
        {key: 'statistics_digest.monthly_active_users', value: mau_for_period},
        {key: 'statistics_digest.dau_mau', value: "#{health_for_period}%",
         description_index: 2}
      ],
      descriptions: [
        {key: 'statistics_digest.dau_description'},
        {key: 'statistics_digest.dau_mau_description'}
      ]
    }

    user_data = {
      title_key: 'statistics_digest.users_section_title',
      fields: [
        {key: 'statistics_digest.new_users', value: new_users(months_ago)},
        {key: 'statistics_digest.repeat_new_users', value: repeat_new_users(months_ago, 2)},
        {key: 'statistics_digest.user_visits', value: user_visits(months_ago)},
        {key: 'statistics_digest.inactive_users', value: inactive_users_for_period}
      ]
    }

    user_action_data = {
      title_key: 'statistics_digest.user_actions_title',
      fields: [
        {key: 'statistics_digest.posts_read', value: posts_read(months_ago)},
        {key: 'statistics_digest.posts_liked', value: posts_liked(months_ago)},
        {key: 'statistics_digest.topics_solved', value: topics_solved(months_ago)},
        {key: 'statistics_digest.flagged_posts', value: flagged_posts(months_ago)}
      ]
    }

    content_data = {
      title_key: 'statistics_digest.content_title',
      fields: [
        {key: 'statistics_digest.topics_created', value: topics_created(months_ago, 'regular')},
        {key: 'statistics_digest.topic_replies_created', value: posts_created(months_ago, 'regular', true)},
        {key: 'statistics_digest.messages_created', value: topics_created(months_ago, 'private_message')},
      ]
    }

    data_array = [
      health_data,
      user_data,
      content_data,
      user_action_data
    ]

    @data = {
      header_metadata: header_metadata,
      data_array: data_array,
      title: digest_title(months_ago),
      subject: digest_title(months_ago),
    }

    admin_emails = User.where(admin: true).map(&:email).select {|e| e.include?('@')}

    mail(to: admin_emails, subject: subject)
  end

  # helper methods
  def dir_for_locale
    rtl? ? 'rtl' : 'ltr'
  end

  def logo_url
    logo_url = SiteSetting.digest_logo_url
    logo_url = SiteSetting.logo_url if logo_url.blank? || logo_url =~ /\.svg$/i

    return nil if logo_url.blank? || logo_url =~ /\.svg$/i
    if logo_url !~ /http(s)?\:\/\//
      logo_url = "#{Discourse.base_url}#{logo_url}"
    end

    logo_url
  end

  def header_color
    "##{ColorScheme.hex_for_name('header_primary')}"
  end

  def header_bgcolor
    "##{ColorScheme.hex_for_name('header_background')}"
  end

  def anchor_color
    "##{ColorScheme.hex_for_name('tertiary')}"
  end

  def bg_color
    '#eeeeee'
  end

  def text_color
    '#222222'
  end

  def highlight_bgcolor
    '#2F70AC'
  end

  def highlight_color
    '#ffffff'
  end

  def body_bgcolor
    '#ffffff'
  end

  def body_color
    '#222222'
  end

  def report_date(months_ago)
    months_ago.month.ago.strftime('%B %Y')
  end

  def digest_title(months_ago)
    "#{I18n.t('statistics_digest.title')} #{report_date(months_ago)}"
  end

  def spacer_color(outer_count, inner_count = 0)
    outer_count == 0 && inner_count == 0 ? highlight_bgcolor : bg_color
  end

  def table_border_style(total_rows, current_row)
    unless total_rows - 1 == current_row
      "border-bottom:1px solid #dddddd;"
    end
  end

  def site_link(color)
    "<a style='text-decoration:none;color:#{color}' href='#{Discourse.base_url}' style='color: #{color}'>#{SiteSetting.title}</a>"
  end

  def statistics_digest_link(color)
    "<a style='text-decoration:none;color:#{color}' href='#{Discourse.base_url}/admin/plugins/admin-statistics-digest' style='color: #{color}'>#{t 'statistics_digest.here'}</a>"
  end

  def superscript(count)
    "<sup style='line-height:0;font-size:70%;vertical-align:top;mso-text-raise:60%'>[#{count}]</sup>"
  end

  private

  def active_users(months_ago = nil)
    active_users = report.active_users do |r|
      r.months_ago months_ago if months_ago
    end

    active_users[0]['active_users'] ? active_users[0]['active_users'] : 0
  end

  def all_users
    User.where('id > 0').count
  end

  def user_visits(months_ago)
    user_visits = report.user_visits do |r|
      r.months_ago months_ago
    end

    user_visits[0]['user_visits']
  end

  def daily_active_users(months_ago)
    daily_active_users = report.daily_active_users do |r|
      r.months_ago months_ago
    end

    visits = daily_active_users[0]['visits']
    days = daily_active_users[0]['days_in_period']

    if visits.is_a? Numeric
      (visits/days).round(2)
    else
      0
    end
  end

  def posts_created(months_ago, archetype, exclude_topic = false)
    posts = report.posts_created do |r|
      r.months_ago months_ago
      r.archetype archetype
      r.exclude_topic exclude_topic
    end

    posts[0]['posts_created']
  end

  def posts_read(months_ago)
    posts = report.posts_read do |r|
      r.months_ago months_ago
    end

    posts[0]['posts_read'] ? posts[0]['posts_read'] : 0
  end

  def topics_created(months_ago, archetype)
    topics = report.topics_created do |r|
      r.months_ago months_ago
      r.archetype archetype
    end

    topics[0]['topics_created']
  end

  def new_users(months_ago)
    new_users = report.new_users do |r|
      r.months_ago months_ago
    end

    new_users[0]['users']
  end

  def repeat_new_users(months_ago, repeats = 2)
    repeat_new_users = report.new_users do |r|
      r.months_ago months_ago
      r.repeats repeats
    end

    repeat_new_users[0]['users']
  end

  def posts_liked(months_ago)
    posts_liked = report.user_actions do |r|
      r.months_ago months_ago
      r.action_type 1
    end

    posts_liked[0]['user_action']
  end

  def topics_solved(months_ago)
    topics_solved = report.user_actions do |r|
      r.months_ago months_ago
      r.action_type 15
    end

    topics_solved[0]['user_action']
  end

  def flagged_posts(months_ago)
    flagged_posts = report.flagged_posts do |r|
      r.months_ago months_ago
    end

    flagged_posts[0]['flagged_posts']
  end

  def health( dau, mau)
    if (dau > 0 && mau > 0)
      (dau * 100 / mau).round(2)
    else
      0
    end
  end

  def report
    @report ||= AdminStatisticsDigest::Report.new
  end
end
