module Health
  class Check
    def self.call
      database = database_status
      redis = redis_status
      {
        status: database == "ok" && redis == "ok" ? "ok" : "error",
        database: database,
        redis: redis
      }
    end

    def self.database_status
      ActiveRecord::Base.connection.execute("SELECT 1")
      "ok"
    rescue StandardError
      "error"
    end

    def self.redis_status
      client = Redis.new(url: ENV.fetch("REDIS_URL", "redis://127.0.0.1:6379/0"))
      client.ping
      "ok"
    rescue StandardError
      "error"
    ensure
      client&.close
    end
  end
end
