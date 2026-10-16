class PingJob < ApplicationJob
  queue_as :default

  # Proves the worker can run a job and write through the cache.
  def perform
    Rails.cache.write("shopkeep:last_ping", Time.now.utc.iso8601, expires_in: 5.minutes)
  end
end
