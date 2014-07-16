namespace :jobs do

  desc "Schedule delayed_job for project."
  task :schedule => [:merb_env, :environment] do
    
    #--- schedule jobs
    # Delayed::Job.schedule  job, prio, start_at, repeat_every
    Delayed::Job.schedule ExpireKasesJob.new, 1, Time.now.utc, 1.minute
    Delayed::Job.schedule ExpirePartnerMembershipsJob.new, 0, Time.now.utc.midnight, 1.day
    Delayed::Job.schedule ImportExchangeRatesJob.new, -1, Time.now.utc.midnight, 1.day
    Delayed::Job.schedule RefreshSitemapJob.new, -1, Time.now.utc.midnight + 1.minute, 1.day
    Delayed::Job.schedule DeleteAllPendingPublicationJob.new, -2, Time.now.utc.midnight + 2.minutes, 1.day
    Delayed::Job.schedule DeleteExpiredSessionsJob.new, -2, Time.now.utc.midnight + 3.minutes, 1.day
    Delayed::Job.schedule PingServiceJob.new, -2, Time.now.utc, 5.minutes

    #--- queue jobs
    # Delayed::Job.enqueue  job, prio

  end

end
