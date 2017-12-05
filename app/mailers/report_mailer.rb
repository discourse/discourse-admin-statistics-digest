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
    # set months_ago to 1 for testing
    months_ago = [0, 1, 2, 3]

    # users
    period_all_users = all_users(months_ago)
    period_active_users = active_users(months_ago)
    period_user_visits = user_visits(months_ago)
    period_dau = daily_active_users(months_ago)
    period_health = health(months_ago)
    period_new_users = new_users(months_ago)
    period_repeat_new_users = new_users(months_ago, repeats: 2)

    # content
    period_posts_created = posts_created(months_ago, archetype: 'regular')
    period_responses_created = posts_created(months_ago, archetype: 'regular', exclude_topic: true)
    period_topics_created = topics_created(months_ago)
    period_message_created = topics_created(months_ago, archetype: 'private_message')

    # actions
    period_posts_read = posts_read(months_ago)
    period_posts_flagged = flagged_posts(months_ago)
    period_posts_liked = user_actions(months_ago, action_type: 1)
    period_topics_solved = user_actions(months_ago, action_type: 15)

    header_metadata = [
      # {key: 'statistics_digest.active_users', value: period_active_users[:current], display: period_active_users[:display]},
      # {key: 'statistics_digest.posts_created', value: period_posts_created[:current], display: period_posts_created[:display]},
      # {key: 'statistics_digest.posts_read', value: period_posts_read[:current], display: period_posts_read[:display]}
      period_active_users,
      period_posts_created,
      period_posts_read
    ]

    health_data = {
      title_key: 'statistics_digest.community_health_title',
      fields: [
        # {key: 'statistics_digest.daily_active_users', value: period_dau[:current], compare: period_dau[:compare], display: period_dau[:display], description_index: 1},
        # {key: 'statistics_digest.monthly_active_users', value: period_active_users[:current], compare: period_active_users[:compare], display: period_active_users[:display]},
        # {key: 'statistics_digest.dau_mau', value: period_health[:current], compare: period_health[:compare], display: period_health[:display], description_index: 2}
        period_dau,
        period_active_users,
        period_health,

      ],
      descriptions: [
        {key: 'statistics_digest.dau_description'},
        {key: 'statistics_digest.dau_mau_description'}
      ]
    }

    user_data = {
      title_key: 'statistics_digest.users_section_title',
      fields: [
        # {key: 'statistics_digest.all_users', value: period_all_users[:current], compare: period_all_users[:compare], display: period_all_users[:display]},
        # {key: 'statistics_digest.new_users', value: period_new_users[:current]},
        # {key: 'statistics_digest.repeat_new_users', value: period_repeat_new_users[:current]},
        # {key: 'statistics_digest.user_visits', value: period_user_visits[:current]},
        # {key: 'statistics_digest.inactive_users', value: inactive_users_for_period}
        period_all_users,
        period_new_users,
        period_repeat_new_users,
        period_user_visits
      ]
    }

    user_action_data = {
      title_key: 'statistics_digest.user_actions_title',
      fields: [
        # {key: 'statistics_digest.posts_read', value: period_posts_read[:current]},
        # {key: 'statistics_digest.posts_liked', value: period_posts_liked[:current]},
        # {key: 'statistics_digest.topics_solved', value: period_topics_solved[:current]},
        # {key: 'statistics_digest.flagged_posts', value: period_posts_flagged[:current]}
        period_posts_read,
        period_posts_liked,
        period_topics_solved,
        period_posts_flagged
      ]
    }

    content_data = {
      title_key: 'statistics_digest.content_title',
      fields: [
        # {key: 'statistics_digest.topics_created', value: period_topics_created[:current]},
        # {key: 'statistics_digest.topic_replies_created', value: period_responses_created[:current]},
        # {key: 'statistics_digest.messages_created', value: period_message_created[:current]},
        period_topics_created,
        period_responses_created,
        period_message_created
      ]
    }

    data_array = [
      health_data,
      user_data,
      content_data,
      user_action_data
    ]

    subject = digest_title(months_ago[0])

    @data = {
      header_metadata: header_metadata,
      data_array: data_array,
      title: subject,
      subject: subject
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

  # users

  def all_users(months_ago)
    all_users = report.all_users do |r|
      r.months_ago months_ago
    end

    compare_with_previous(all_users, 'all_users')
  end

  def new_users(months_ago, repeats: 1)
    new_users = report.new_users do |r|
      r.months_ago months_ago
      r.repeats repeats
    end

    compare_with_previous( new_users, 'new_users')
  end

  def active_users(months_ago)
    active_users = report.active_users do |r|
      r.months_ago months_ago
    end

    compare_with_previous(active_users, 'active_users')
  end

  def user_visits(months_ago)
    user_visits = report.user_visits do |r|
      r.months_ago months_ago
    end

    compare_with_previous(user_visits, 'user_visits')
  end

  def daily_active_users(months_ago)
    daily_active_users = report.daily_active_users do |r|
      r.months_ago months_ago
    end

    compare_with_previous(daily_active_users, 'daily_active_users')
  end

  # todo: this is making a couple of extra queries. It could use the existing dau/mau data hash
  # but thet will limit the ability to get comparisons for more months if we choose to do that
  # in the future.
  def health(months_ago, display_threshold: -20)
    daily_active_users = report.daily_active_users do |r|
      r.months_ago months_ago
    end

    monthly_active_users = report.active_users do |r|
      r.months_ago months_ago
    end

    current_dau = value_for_key(daily_active_users, 0, 'daily_active_users')
    prev_dau = value_for_key(daily_active_users, 1, 'daily_active_users')
    current_mau = value_for_key(monthly_active_users, 0, 'active_users')
    prev_mau = value_for_key(monthly_active_users, 1, 'active_users')

    current_health = calculate_health(current_dau, current_mau)
    prev_health = calculate_health(prev_dau, prev_mau)
    # todo: is there a standard way of comparing percentages?
    compare = current_health - prev_health

    #todo: check the value that's being used for compare!
    {
      key: 'statistics_digest.dau_mau',
      value: format_percent(current_health),
      compare: format_percent(compare.round(2)),
      has_description: true,
      display: compare > display_threshold
    }
  end

  # content

  def posts_created(months_ago, archetype: 'regular', exclude_topic: nil)
    posts_created = report.posts_created do |r|
      r.months_ago months_ago
      r.archetype archetype
      r.exclude_topic exclude_topic if exclude_topic
    end

    compare_with_previous(posts_created, 'posts_created')
  end

  def topics_created(months_ago, archetype: 'regular')
    topics_created = report.topics_created do |r|
      r.months_ago months_ago
      r.archetype archetype
    end

    compare_with_previous(topics_created, 'topics_created')
  end

  # actions

  def posts_read(months_ago)
    posts_read = report.posts_read do |r|
      r.months_ago months_ago
    end

    compare_with_previous(posts_read, 'posts_read')
  end

  def flagged_posts(months_ago)
    flagged_posts = report.flagged_posts do |r|
      r.months_ago months_ago
    end

    compare_with_previous(flagged_posts, 'flagged_posts')
  end

  def user_actions(months_ago, action_type:)
    user_actions = report.user_actions do |r|
      r.months_ago months_ago
      r.action_type action_type
    end

    compare_with_previous(user_actions, 'actions')
  end

  def percent_diff(current, previous)
    if current && previous && previous > 0
      (current - previous) * 100.0 / previous
    elsif current
      100.00
    else
      0
    end
  end

  def value_for_key(arr, pos, key)
    arr[pos][key] if arr[pos]
  end

  def format_diff(diff)
    sprintf("%+d%", diff)
  end

  def format_percent(num)
    "#{num}%"
  end

  def compare_with_previous(arr, field_key, translation_key: nil, has_description: false, display_threshold: -20)
    current = value_for_key(arr, 0, field_key)
    previous = value_for_key(arr, 1, field_key)
    compare = percent_diff(current, previous)
    formatted_compare = format_diff(compare)

    current = current.round(2) if current.is_a? Float
    if translation_key
      text_key = "statistics_digest.#{translation_key}"
    else
      text_key = "statistics_digest.#{field_key}"
    end

    {
      key: text_key,
      value: current,
      compare: formatted_compare,
      has_description: has_description,
      display: compare > display_threshold
    }
  end

  def calculate_health(dau, mau)
    if dau > 0 && mau > 0
      (dau * 100 / mau).round(2)
    else
      0
    end
  end

  def report
    @report ||= AdminStatisticsDigest::Report.new
  end
end
