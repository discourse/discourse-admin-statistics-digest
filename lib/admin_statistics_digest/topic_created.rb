require_relative '../admin_statistics_digest/base_report'

class AdminStatisticsDigest::TopicCreated < AdminStatisticsDigest::BaseReport

  provide_filter :months_ago
  provide_filter :archetype

  def to_sql
    <<~SQL
SELECT
count(1) AS "topics_created"
FROM "topics" "t"
WHERE "t"."created_at" >= '#{filters.months_ago[:period_start]}'
AND "t"."created_at" <= '#{filters.months_ago[:period_end]}'
AND "t"."user_id" > 0
AND "t"."archetype" = '#{filters.archetype}'
    SQL
  end

end
