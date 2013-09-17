require "spec_helper"

describe Rack::Inspector do
  let(:redis)      { Redis.new }
  let(:options)    { Hash[redis: redis] }
  let(:middleware) { Rack::Inspector.new(default_app, options) }

  describe "#initialize" do
    it "assigns hostname" do
      expect(middleware.hostname).not_to be_empty
    end

    it "assigns name" do
      expect(middleware.name).to eq "rack"
    end

    it "assigns empty routes" do
      expect(middleware.routes).to eq []
    end

    context "with non-regex routes" do
      let(:options) { Hash[match: ["a", "b", "c"]] }

      it "raises exception" do
        expect { middleware }.to raise_error ArgumentError, "Non-regular expessions in match"
      end
    end

    context "with duplicate routes" do
      let(:options) { Hash[match: [/a/, /a/, /b/]] }

      it "removes duplicates" do
        expect(middleware.routes.size).to eq 2
      end
    end

    context "with a single route" do
      let(:options) { Hash[match: /a/] }

      it "converts it to array" do
        expect(middleware.routes).to be_an Array
      end
    end
  end

  it "does not report anything by default" do
    expect(middleware).not_to receive(:deliver_payload)
    middleware.call env_for("http://foobar.com/")
  end

  it "reports only on specified routes" do
    middleware = Rack::Inspector.new(default_app, redis: redis, match: [/hello/])
    expect(middleware).to receive(:deliver_payload).once

    middleware.call env_for("http://foobar.com/")
    middleware.call env_for("http://foobar.com/hello")
  end

  it "reports on all routes" do
    middleware = Rack::Inspector.new(default_app, redis: redis, match_all: true)
    expect(middleware).to receive(:deliver_payload).twice

    middleware.call env_for("http://foobar.com/")
    middleware.call env_for("http://foobar.com/hello")
  end

  it "reports on matching response code" do
    middleware = Rack::Inspector.new(error_app, redis: redis, status: 400, match_all: true)
    expect(middleware).to receive(:deliver_payload).once    
    
    middleware.call env_for("http://foobar.com/hello")
  end

  it "ignores non-specified response code" do
    middleware = Rack::Inspector.new(default_app, redis: redis, status: 400, match_all: true)
    expect(middleware).not_to receive(:deliver_payload)

    middleware.call env_for("http://foobar.com/hello")
  end

  it "sends json payload" do
    middleware = Rack::Inspector.new(default_app, redis: redis, match_all: true)
    middleware.call env_for("http://foobar.com/hello")

    payload = JSON.parse(redis.lpop("reports"))

    expect(payload["id"]).to match /^[a-f\d\-]+$/
    expect(payload["app"]).to eq "rack"
    expect(payload["host"]).not_to be_empty
    expect(payload["request_method"]).to eq "GET"
    expect(payload["path"]).to eq "/hello"
    expect(payload["status"]).to eq 200
    expect(payload["timestamp"]).not_to be_empty
  end
end