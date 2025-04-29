# frozen_string_literal: true

require 'rspec'
require 'mail'

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.syntax = :expect
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  # Optional: Show full backtrace for failures
  config.full_backtrace = false

  # Optional: Run specs in random order to surface order dependencies.
  config.order = :random

  # Optional: enable warnings
  config.warnings = true
end
