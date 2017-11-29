require_relative '../admin_statistics_digest/base_report'

class AdminStatisticsDigest::DailyActiveUser < AdminStatisticsDigest::BaseReport

  provide_filter :months_ago

  def to_sql
    <<~SQL
WITH daily_visits AS(    
SELECT
count(1) as "daily_visits"
FROM "user_visits" "uv"
WHERE "uv"."visited_at" >= '#{filters.months_ago[:period_start]}'
AND "uv"."visited_at" <= '#{filters.months_ago[:period_end]}'
GROUP BY "uv"."visited_at")

SELECT
sum(daily_visits) as "visits",
EXTRACT(DAY FROM DATE '#{filters.months_ago[:period_end]}')  AS "days_in_period"
FROM daily_visits
    SQL
  end
end
