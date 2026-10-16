class AuditEvent < ApplicationRecord
  belongs_to :store
  belongs_to :actor, class_name: "User", optional: true

  validates :action, presence: true
  validates :metadata, exclusion: { in: [ nil ] }
end
