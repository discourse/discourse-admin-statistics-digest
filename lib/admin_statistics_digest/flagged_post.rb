require_relative '../admin_statistics_digest/base_report'

class AdminStatisticsDigest::FlaggedPost < AdminStatisticsDigest::BaseReport

  provide_filter :months_ago

  def to_sql
    <<~SQL
SELECT
count(1) as "flagged_posts"
FROM "post_actions" "pa"
JOIN "post_action_types" "pat"
ON "pat"."id" = "pa"."post_action_type_id"
WHERE "pa"."created_at" >= '#{filters.months_ago[:period_start]}'
AND "pa"."created_at" <= '#{filters.months_ago[:period_end]}'
AND "pat"."is_flag" = 't'
AND "pa"."agreed_at" IS NOT NULL
    SQL
  end
end
