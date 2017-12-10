require_relative '../admin_statistics_digest/base_report'

class AdminStatisticsDigest::FlaggedPost < AdminStatisticsDigest::BaseReport
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
count(pat.id) AS flagged_posts
FROM post_actions pa
JOIN post_action_types pat
ON pat.id = pa.post_action_type_id
AND pat.is_flag = 't'
RIGHT JOIN periods p
ON pa.created_at >= p.period_start
AND pa.created_at <= p.period_end
GROUP BY p.months_ago
ORDER BY p.months_ago
    SQL
  end
end
