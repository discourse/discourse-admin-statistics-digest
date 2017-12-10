require_relative '../admin_statistics_digest/base_report'

class AdminStatisticsDigest::TopicCreated < AdminStatisticsDigest::BaseReport

  provide_filter :months_ago
  provide_filter :archetype

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
count(t.id) AS topics_created
FROM topics t
RIGHT JOIN periods p
ON t.created_at >= p.period_start
AND t.created_at <= p.period_end
AND t.user_id > 0
AND t.archetype = '#{filters.archetype}'
GROUP BY p.months_ago
ORDER BY p.months_ago
    SQL
  end

end
