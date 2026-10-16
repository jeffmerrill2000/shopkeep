class OutboxDrainJob < ApplicationJob
  queue_as :default

  def perform
    OutboxEvent.where(published_at: nil).order(:id).limit(100).each do |event|
      event.update!(published_at: Time.current)
    end
  end
end
