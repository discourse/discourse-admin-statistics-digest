require_relative '../admin_statistics_digest/base_report'

class AdminStatisticsDigest::UserAction < AdminStatisticsDigest::BaseReport

  provide_filter :months_ago
  provide_filter :action_type

  def to_sql
    <<~SQL
SELECT count(1) AS "user_action"
FROM "user_actions" "ua"
WHERE "ua"."created_at" >= '#{filters.months_ago[:period_start]}'
AND "ua"."created_at" <= '#{filters.months_ago[:period_end]}'
AND "ua"."action_type" = '#{filters.action_type}'
    SQL
  end
end
