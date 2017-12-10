require_relative '../admin_statistics_digest/base_report'

class AdminStatisticsDigest::PostRead < AdminStatisticsDigest::BaseReport

  provide_filter :months_ago

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
COALESCE(sum(uv.posts_read), 0) AS posts_read
FROM user_visits uv
RIGHT JOIN periods p
ON uv.visited_at >= p.period_start
AND uv.visited_at <= p.period_end
GROUP BY p.months_ago
ORDER BY p.months_ago
    SQL
  end
end
