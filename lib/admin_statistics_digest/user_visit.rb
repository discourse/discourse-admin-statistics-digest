require_relative '../admin_statistics_digest/base_report'

class AdminStatisticsDigest::UserVisit < AdminStatisticsDigest::BaseReport

  provide_filter :months_ago

  def to_sql
    <<~SQL
SELECT
count(1) as "user_visits"
FROM "user_visits" "uv"
WHERE "uv"."visited_at" >= '#{filters.months_ago[:period_start]}'
AND "uv"."visited_at" <= '#{filters.months_ago[:period_end]}'
    SQL
  end
end
