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
      expect(middleware.name).to eq "rack-inspector"
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

    context "with custom redis url" do
      before do
        ENV["REDIS_INSPECT_URL"] = "redis://username@localhost2:6379"
      end

      after do
        ENV["REDIS_INSPECT_URL"] = nil
      end

      let(:middleware) do
        Rack::Inspector.new(default_app, redis: nil)
      end

      it "connects to custom redis server" do
        conn = middleware.instance_variable_get("@redis")

        expect(conn.client.host).to eq "localhost2"
        expect(conn.client.port).to eq 6379
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
    expect(payload["app"]).to eq "rack-inspector"
    expect(payload["host"]).not_to be_empty
    expect(payload["request_method"]).to eq "GET"
    expect(payload["path"]).to eq "/hello"
    expect(payload["status"]).to eq 200
    expect(payload["timestamp"]).not_to be_empty
  end
end