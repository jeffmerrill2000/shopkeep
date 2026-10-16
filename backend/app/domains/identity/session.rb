class Session < ApplicationRecord
  belongs_to :user

  before_validation :truncate_user_agent

  private
    def truncate_user_agent
      self.user_agent = user_agent.to_s.byteslice(0, 255)
    end
end
