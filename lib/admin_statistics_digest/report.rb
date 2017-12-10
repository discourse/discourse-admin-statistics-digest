require_relative './all_user'
require_relative './active_user'
require_relative './post_read'
require_relative './post_created'
require_relative './topic_created'
require_relative './new_user'
require_relative './user_action'
require_relative './flagged_post'

class AdminStatisticsDigest::Report

  REPORTS = {
    all_users: AdminStatisticsDigest::AllUser,
    active_users: AdminStatisticsDigest::ActiveUser,
    posts_read: AdminStatisticsDigest::PostRead,
    posts_created: AdminStatisticsDigest::PostCreated,
    new_users: AdminStatisticsDigest::NewUser,
    topics_created: AdminStatisticsDigest::TopicCreated,
    user_actions: AdminStatisticsDigest::UserAction,
    flagged_posts: AdminStatisticsDigest::FlaggedPost
  }.freeze

  def self.generate(&block)
    self.new(&block)
  end

  def initialize(&block)
    self.rows = []

    instance_eval(&block) if block_given?
  end

  REPORTS.each do |method_name, klass_name|

    define_method(method_name.to_sym) do |&block|
      report = klass_name.new
      report.instance_eval(&block)
      result = report.execute
      if result[:error]
        raise result[:error]
      else
        self.send(:rows).push(result[:data])
        result[:data]
      end
    end

  end

  def section(name, &block)
    rows << {
      name: name,
      data: AdminStatisticsDigest::Report.new(&block).data
    }
  end

  def size
    rows.size
  end

  def data
    return rows.flatten.freeze if rows.length == 1
    rows.freeze
  end

  private
  attr_accessor :rows

end
