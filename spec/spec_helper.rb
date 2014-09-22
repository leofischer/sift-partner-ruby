
require "bundler/setup"
require "sift-partner"
require "webmock/rspec"

# Setup Fakeweb
WebMock.disable_net_connect!

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = :should
  end
  config.mock_with :rspec do |c|
    c.syntax = :should
  end
end
