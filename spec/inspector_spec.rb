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
      let(:options) { Hash[path: ["a", "b", "c"]] }

      it "raises exception" do
        expect { middleware }.to raise_error ArgumentError, "Non-regular expessions in path"
      end
    end

    context "with duplicate routes" do
      let(:options) { Hash[path: [/a/, /a/, /b/]] }

      it "removes duplicates" do
        expect(middleware.routes.size).to eq 2
      end
    end

    context "with a single route" do
      let(:options) { Hash[path: /a/] }

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

  it "reports everything by default" do
    expect(middleware).to receive(:deliver_payload)
    middleware.call env_for("http://foobar.com/")
  end

  it "reports on matching path only" do
    middleware = Rack::Inspector.new(default_app, redis: redis, path: [/hello/])
    expect(middleware).to receive(:deliver_payload).once

    middleware.call env_for("http://foobar.com/")
    middleware.call env_for("http://foobar.com/hello")
  end

  it "reports on matching response code" do
    middleware = Rack::Inspector.new(error_app, redis: redis, status: 400)
    expect(middleware).to receive(:deliver_payload).once    
    
    middleware.call env_for("http://foobar.com/hello")
  end

  it "does not report if status does not match" do
    middleware = Rack::Inspector.new(default_app, redis: redis, status: 400)
    expect(middleware).not_to receive(:deliver_payload)

    status, _, _ = middleware.call env_for("http://foobar.com/hello")
    expect(status).not_to eq 400
  end

  it "reports on matching request method" do
    middleware = Rack::Inspector.new(default_app, redis: redis, method: "POST")
    expect(middleware).to receive(:deliver_payload).once

    middleware.call env_for("http://foobar.com/hello", method: "GET")
    middleware.call env_for("http://foobar.com/hello", method: "POST")
    middleware.call env_for("http://foobar.com/hello", method: "PUT")
    middleware.call env_for("http://foobar.com/hello", method: "DELETE")
    middleware.call env_for("http://foobar.com/hello", method: "PATCH")
  end

  it "does not report if request method does not match" do
    middleware = Rack::Inspector.new(default_app, redis: redis, method: "GET")
    expect(middleware).not_to receive(:deliver_payload)

    middleware.call env_for("http://foobar.com/hello", method: "POST")
    middleware.call env_for("http://foobar.com/hello", method: "PUT")
    middleware.call env_for("http://foobar.com/hello", method: "DELETE")
    middleware.call env_for("http://foobar.com/hello", method: "PATCH")
  end

  it "reports if path and method match" do
    middleware = Rack::Inspector.new(default_app, redis: redis, path: /hello/, method: "POST")
    expect(middleware).to receive(:deliver_payload).once

    middleware.call env_for("http://foobar.com/hello", method: "POST")
    middleware.call env_for("http://foobar.com/hey", method: "POST")
    middleware.call env_for("http://foobar.com/hey", method: "GET")
  end

  it "reports if path, method and status match" do
    middleware = Rack::Inspector.new(error_app, redis: redis, path: /hello/, method: "POST", status: 400)
    expect(middleware).to receive(:deliver_payload).once

    middleware.call env_for("http://foobar.com/hello", method: "POST")
    middleware.call env_for("http://foobar.com/hello", method: "GET")
    middleware.call env_for("http://foobar.com/hey", method: "POST")
  end

  it "sends json payload" do
    middleware = Rack::Inspector.new(default_app, redis: redis)
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