module MoneyCents
  module_function

  def parse(value)
    integer = strict_integer(value, allow_negative: false)
    raise DomainError.new("invalid_amount", "Amounts must be zero or a positive integer number of minor units") if integer.nil?

    integer
  end

  def parse_delta(value)
    integer = strict_integer(value, allow_negative: true)
    raise DomainError.new("invalid_amount", "Stock changes must be a non-zero integer") if integer.nil? || integer.zero?

    integer
  end

  def strict_integer(value, allow_negative:)
    case value
    when Integer
      return nil if !allow_negative && value.negative?
      value
    when String
      pattern = allow_negative ? /\A-?[0-9]+\z/ : /\A[0-9]+\z/
      return nil unless value.match?(pattern)

      Integer(value, 10)
    else
      nil
    end
  end
end
