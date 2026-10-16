class DomainError < StandardError
  attr_reader :code, :status, :details

  def initialize(code, message, status: :unprocessable_content, details: {})
    super(message)
    @code = code
    @status = status
    @details = details
  end
end
