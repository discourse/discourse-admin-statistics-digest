require_relative '../admin_statistics_digest/base_report'

class AdminStatisticsDigest::UserAction < AdminStatisticsDigest::BaseReport

  provide_filter :months_ago
  provide_filter :action_type

  def to_sql
    <<~SQL
WITH periods AS (
SELECT
months_ago,
date_trunc('month', CURRENT_DATE) - INTERVAL '1 months' * months_ago AS period_start,
date_trunc('month', CURRENT_DATE) - INTERVAL '1 months' * months_ago + INTERVAL '1 month' - INTERVAL '1 second' AS period_end
FROM unnest(ARRAY #{filters.months_ago}) AS months_ago
)

SELECT
p.months_ago,
COALESCE(COUNT(ua.id), 0) AS actions
FROM user_actions ua
RIGHT JOIN periods p
ON ua.created_at >= p.period_start
AND ua.created_at <= p.period_end
AND ua.action_type = #{filters.action_type}
GROUP BY p.months_ago
ORDER BY p.months_ago
    SQL
  end
end
