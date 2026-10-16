class SessionLogin
  def self.authenticate(email:, password:)
    User.authenticate_by(email: email.to_s.strip.downcase, password: password.to_s)
  end
end
