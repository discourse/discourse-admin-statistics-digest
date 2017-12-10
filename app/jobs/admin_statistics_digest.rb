module ::Jobs
  class AdminStatisticsDigest < ::Jobs::Scheduled
    every 1.day
    sidekiq_options 'retry' => true, 'queue' => 'critical'

    def execute(opts = nil)

      return unless DateTime.now.day == 1

      ::AdminStatisticsDigest::ReportMailer.digest(1).deliver_now
    end
  end
end
