require_relative '../admin_statistics_digest/base_report'

class AdminStatisticsDigest::PostCreated < AdminStatisticsDigest::BaseReport

  provide_filter :months_ago
  provide_filter :archetype
  provide_filter :exclude_topic

  def to_sql
    exclude_topic_filter = if filters.exclude_topic
                             <<~SQL
                             AND "p"."post_number" > 1
                             SQL
                           else
                             nil
                           end
    <<~SQL
SELECT
count(1) AS "posts_created"
FROM "posts" "p"
JOIN "topics" "t"
ON "t"."id" = "p"."topic_id"
WHERE "p"."created_at" >= '#{filters.months_ago[:period_start]}'
AND "p"."created_at" <= '#{filters.months_ago[:period_end]}'
AND "t"."archetype" = '#{filters.archetype}'
AND "p"."user_id" > 0
#{exclude_topic_filter}
    SQL
  end
end
