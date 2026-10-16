ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../Gemfile", __dir__)

require "bundler/setup" # Set up gems listed in the Gemfile.
begin
  require "dotenv"
  # Repository-root env file. Existing variables win, so RAILS_ENV=test is preserved.
  # The gem is in the development/test group, so production boots without it.
  Dotenv.load(File.expand_path("../../.env", __dir__))
rescue LoadError
  nil
end
require "bootsnap/setup" # Speed up boot time by caching expensive operations.
