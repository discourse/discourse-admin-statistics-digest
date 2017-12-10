require_relative '../helpers/report_helper'

class AdminStatisticsDigest::ReportMailer < ActionMailer::Base
  include Rails.application.routes.url_helpers
  include ApplicationHelper
  include ReportHelper
  helper :application
  default charset: 'UTF-8'

  helper_method :dir_for_locale, :logo_url, :header_color, :header_bgcolor, :anchor_color,
                :bg_color, :text_color, :highlight_bgcolor, :highlight_color, :body_bgcolor,
                :body_color, :report_date, :digest_title, :spacer_color, :table_border_style,
                :site_link, :statistics_digest_link, :superscript

  append_view_path Rails.root.join('plugins', 'discourse-admin-statistics-digest', 'app', 'views')
  default from: SiteSetting.notification_email

  def digest(months_ago, num_months: 2)
    months_ago = (0...num_months).to_a.map {|i| i + months_ago}
    period_month = (months_ago[0]).months.ago.strftime('%B')

    # users
    period_dau = daily_active_users(months_ago, display_threshold: -20)
    period_all_users = all_users(months_ago, description_key: 'all_users_description', display_threshold: -20)
    period_active_users = active_users(months_ago, distinct: true, description_key: 'active_users_description', display_threshold: -20)
    period_user_visits = active_users(months_ago, distinct: false, translation_key: 'user_visits', description_key: 'user_visits_description', display_threshold: -20)
    period_health = health(months_ago, display_threshold: -20)
    period_new_users = new_users(months_ago, translation_key: 'new_users', description_key: 'new_users_description', display_threshold: -20)
    period_repeat_new_users = new_users(months_ago, repeats: 2, translation_key: 'repeat_new_users', description_key: 'repeat_new_users_description', display_threshold: -20)

    # content
    period_posts_created = posts_created(months_ago, archetype: 'regular')
    period_responses_created = posts_created(months_ago, translation_key: 'replies_created', description_key: 'responses_description', exclude_topic: true, display_threshold: -20)
    period_topics_created = topics_created(months_ago, description_key: 'topics_description', display_threshold: -20)
    period_message_created = topics_created(months_ago, archetype: 'private_message', translation_key: 'messages_created', description_key: 'messages_description', display_threshold: nil)

    # actions
    period_posts_read = posts_read(months_ago, description_key: 'posts_read_description', display_threshold: -20)
    period_posts_flagged = flagged_posts(months_ago, description_key: 'flagged_posts_description', display_threshold: nil)
    period_posts_liked = user_actions(months_ago, 1, translation_key: 'posts_liked', description_key: 'posts_liked_description', display_threshold: -20)
    period_topics_solved = user_actions(months_ago, 15, translation_key: 'topics_solved', description_key: 'topics_solved_description', display_threshold: -20, hide_zero: true)

    header_metadata = [
      period_active_users,
      period_posts_created,
      period_posts_read
    ]

    health_data = {
      title_key: 'statistics_digest.community_health_title',
      fields: [
        period_active_users,
        period_dau,
        period_health,
      ]
    }

    user_data = {
      title_key: 'statistics_digest.users_section_title',
      fields: [
        period_all_users,
        period_new_users,
        period_repeat_new_users,
        period_user_visits
      ]
    }

    user_action_data = {
      title_key: 'statistics_digest.user_actions_title',
      fields: [
        period_posts_read,
        period_posts_liked,
        period_topics_solved,
        period_posts_flagged
      ]
    }

    content_data = {
      title_key: 'statistics_digest.content_title',
      fields: [
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
      period_month: period_month,
      header_metadata: header_metadata,
      data_array: data_array,
      title: subject,
      subject: subject
    }

    admin_emails = User.where(admin: true).map(&:email).select {|e| e.include?('@')}

    mail(to: admin_emails, subject: subject)
  end

  private

  # users

  def all_users(months_ago, opts = {})
    all_users = report.all_users do |r|
      r.months_ago months_ago
    end

    compare_with_previous(all_users, 'all_users', opts)
  end

  def new_users(months_ago, opts = {})
    new_users = report.new_users do |r|
      r.months_ago months_ago
      r.repeats opts[:repeats] ? opts[:repeats] : 1
    end

    compare_with_previous(new_users, 'new_users', opts)
  end

  def active_users(months_ago, opts = {})
    active_users = report.active_users do |r|
      r.months_ago months_ago
      r.distinct opts[:distinct]
    end

    compare_with_previous(active_users, 'active_users', opts)
  end

  def daily_active_users(months_ago, opts = {})
    active_users = report.active_users do |r|
      r.months_ago months_ago
      r.distinct false
    end

    current_active = value_for_key(active_users, 0, 'active_users')
    prev_active = value_for_key(active_users, 1, 'active_users')
    first_p_length = months_ago[0] == 0 ? Date.today.day.to_i : months_ago[0].months_ago.end_of_month.day.to_i
    second_p_length = months_ago[1].months.ago.end_of_month.day.to_i
    current_dau = current_active.to_f / first_p_length
    prev_dau = prev_active.to_f / second_p_length
    compare = percent_diff(current_dau, prev_dau)

    {
      key: 'statistics_digest.daily_active_users',
      value: current_dau,
      compare: format_diff(compare),
      description_key: 'statistics_digest.dau_description',
      hide: opts[:display_threshold] && compare ? compare < opts[:display_threshold] : false
    }
  end

  def health(months_ago, opts = {})
    active_users = report.active_users do |r|
      r.months_ago months_ago
      r.distinct false
    end

    current_monthly_active = value_for_key(active_users, 0, 'active_users')
    prev_monthly_active = value_for_key(active_users, 1, 'active_users')
    first_p_length = months_ago[0] == 0 ? Date.today.day.to_i : months_ago[0].months_ago.end_of_month.day.to_i
    second_p_length = months_ago[1].months.ago.end_of_month.day.to_i
    current_dau = current_monthly_active / first_p_length
    prev_dau = prev_monthly_active / second_p_length

    current_health = calculate_health(current_dau, current_monthly_active)
    prev_health = calculate_health(prev_dau, prev_monthly_active)
    compare = percent_diff(current_health, prev_health)

    {
      key: 'statistics_digest.dau_mau',
      value: current_health,
      compare: format_percent(compare),
      description_key: 'statistics_digest.health_description',
      hide: opts[:display_threshold] && compare ? compare < opts[:display_threshold] : false
    }
  end

  def calculate_health(dau, mau)
    if dau > 0 && mau > 0
      (dau * 100.0 / mau).round(2)
    else
      0
    end
  end

  # content

  def posts_created(months_ago, opts = {})
    posts_created = report.posts_created do |r|
      r.months_ago months_ago
      r.archetype opts[:archetype] ? opts[:archetype] : 'regular'
      r.exclude_topic opts[:exclude_topic]
    end

    compare_with_previous(posts_created, 'posts_created', opts)
  end

  def topics_created(months_ago, opts = {})
    topics_created = report.topics_created do |r|
      r.months_ago months_ago
      r.archetype opts[:archetype] ? opts[:archetype] : 'regular'
    end

    compare_with_previous(topics_created, 'topics_created', opts)
  end

  # actions

  def posts_read(months_ago, opts = {})
    posts_read = report.posts_read do |r|
      r.months_ago months_ago
    end

    compare_with_previous(posts_read, 'posts_read', opts)
  end

  def flagged_posts(months_ago, opts = {})
    flagged_posts = report.flagged_posts do |r|
      r.months_ago months_ago
    end

    compare_with_previous(flagged_posts, 'flagged_posts', opts)
  end

  def user_actions(months_ago, action_type, opts = {})
    user_actions = report.user_actions do |r|
      r.months_ago months_ago
      r.action_type action_type
    end

    compare_with_previous(user_actions, 'actions', opts)
  end

  def percent_diff(current, previous)
    if !(current && previous && previous > 0)
      # no data
      nil
    else
      if current == previous
        0
      else
        diff = current - previous
        diff * 100.0 / previous
      end
    end
  end

  def value_for_key(arr, pos, key)
    arr[pos][key] if arr[pos]
  end

  def format_diff(diff)
    return I18n.t 'statistics_digest.no_data' unless diff

    sprintf("%+d%", diff)
  end

  def format_percent(num)
    return I18n.t 'statistics_digest.no_data' unless num

    "#{num.round(2)}%"
  end

  def compare_with_previous(arr, field_key, opts = {})
    current = value_for_key(arr, 0, field_key)
    previous = value_for_key(arr, 1, field_key)
    compare = percent_diff(current, previous)
    formatted_compare = format_diff(compare)

    current = current.round(2) if current.is_a? Float
    if opts[:translation_key]
      text_key = "statistics_digest.#{opts[:translation_key]}"
    else
      text_key = "statistics_digest.#{field_key}"
    end

    # todo: this is for the solved query. It should be checking if the plugin is active.
    if opts[:hide_zero]
      hide = current == 0
    elsif opts[:display_threshold] && compare
      hide = compare < opts[:display_threshold]
    else
      hide = false
    end

    {
      key: text_key,
      value: current,
      compare: formatted_compare,
      description_key: opts[:description_key] ? "statistics_digest.#{opts[:description_key]}" : nil,
      hide: hide
    }
  end

  def report
    @report ||= AdminStatisticsDigest::Report.new
  end
end
