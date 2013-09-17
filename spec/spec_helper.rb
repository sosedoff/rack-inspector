require "simplecov"
SimpleCov.start do
  add_filter "/.bundle/"
end

require "rack/test"
require "rack/inspector"

ENV['RACK_ENV'] = "test"

RSpec.configure do |config|
  config.include Rack::Test::Methods

  config.before(:each) do
    Redis.current.flushall
  end

  config.after(:each) do
    Redis.current.flushall
  end
end

def fixture_path
  File.expand_path("../fixtures", __FILE__)
end

def fixture(file)
  File.read(File.join(fixture_path, file))
end

def default_app
  lambda do |env|
    headers = {'Content-Type' => "text/html"}
    [200, headers, ["OK"]]
  end
end

def env_for(url, opts = {})
  Rack::MockRequest.env_for(url, opts)
end