require_relative '../admin_statistics_digest/base_report'

class AdminStatisticsDigest::AllUser < AdminStatisticsDigest::BaseReport
  provide_filter :months_ago

  def to_sql
    <<~SQL
WITH periods AS (
SELECT
months_ago,
date_trunc('month', CURRENT_DATE) - INTERVAL '1 months' * months_ago AS period_start,
date_trunc('month', CURRENT_DATE) - INTERVAL '1 months' * months_ago + INTERVAL '1 month' - INTERVAL '1 second' AS period_end
FROM unnest(ARRAY #{filters.months_ago}) as months_ago
)

SELECT
p.months_ago,
count(u.id) AS all_users
FROM users u
RIGHT JOIN periods p
ON u.created_at <= p.period_end
GROUP BY p.months_ago
ORDER BY p.months_ago
    SQL
  end
end
