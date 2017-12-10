require_relative '../admin_statistics_digest/base_report'

class AdminStatisticsDigest::NewUser < AdminStatisticsDigest::BaseReport
  provide_filter :months_ago
  provide_filter :repeats


  def to_sql
    <<~SQL
WITH periods AS (
SELECT
months_ago,
date_trunc('month', CURRENT_DATE) - INTERVAL '1 months' * months_ago AS period_start,
date_trunc('month', CURRENT_DATE) - INTERVAL '1 months' * months_ago + INTERVAL '1 month' - INTERVAL '1 second' AS period_end
FROM unnest(ARRAY #{filters.months_ago}) AS months_ago
),
period_new_users AS (
SELECT
p.months_ago,
u.id AS user_id
FROM users u
RIGHT JOIN periods p
ON u.created_at >= p.period_start
AND u.created_at <= p.period_end
),
period_user_visits AS (
SELECT
uv.user_id,
p.months_ago,
count(uv.user_id) as visits
FROM user_visits uv
RIGHT JOIN periods p
ON uv.visited_at >= p.period_start
AND uv.visited_at <= p.period_end
GROUP BY p.months_ago, uv.user_id
ORDER BY p.months_ago, visits DESC
)

SELECT
pnu.months_ago,
count(puv.user_id) AS new_users
FROM period_new_users pnu
LEFT JOIN period_user_visits puv
ON puv.months_ago = pnu.months_ago
AND puv.user_id = pnu.user_id
AND puv.visits >= #{filters.repeats}
GROUP BY pnu.months_ago
ORDER BY pnu.months_ago
    SQL
  end

end
