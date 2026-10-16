class EventRecorder
  FORBIDDEN_KEY = /password|digest|session|cookie|csrf|token/i

  def self.call(store:, actor:, action:, subject: nil, metadata: {}, ip_address: nil)
    cleaned = sanitize(metadata)
    AuditEvent.create!(
      store: store,
      actor: actor,
      action: action,
      subject_type: subject&.class&.name,
      subject_id: subject&.id,
      metadata: cleaned,
      ip_address: ip_address
    )
  end

  def self.sanitize(metadata)
    raise ArgumentError, "Audit metadata must be a hash" unless metadata.is_a?(Hash)

    metadata.each_with_object({}) do |(key, value), cleaned|
      name = key.to_s
      raise ArgumentError, "Audit metadata cannot include #{name}" if name.match?(FORBIDDEN_KEY)

      cleaned[name] = value
    end
  end
end
