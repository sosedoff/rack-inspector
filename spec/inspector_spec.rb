require "spec_helper"

describe Rack::Inspector do
  let(:redis)      { Redis.new }
  let(:options)    { Hash(redis: redis) }
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
      let(:options) { Hash(match: ["a", "b", "c"]) }

      it "raises exception" do
        expect { middleware }.to raise_error ArgumentError, "Non-regular expessions in match"
      end
    end

    context "with duplicate routes" do
      let(:options) { Hash(match: [/a/, /a/, /b/]) }

      it "removes duplicates" do
        expect(middleware.routes.size).to eq 2
      end
    end

    context "with a single route" do
      let(:options) { Hash(match: /a/) }

      it "converts it to array" do
        expect(middleware.routes).to be_an Array
      end
    end
  end

  it "does not report anything by default" do
    expect(redis).not_to receive(:rpush)
    middleware.call env_for("http://foobar.com/")
  end

  it "reports only on specified routes" do
    expect(redis).to receive(:rpush).once

    middleware = Rack::Inspector.new(default_app, redis: redis, match: [/hello/])
    middleware.call env_for("http://foobar.com/")
    middleware.call env_for("http://foobar.com/hello")
  end

  it "reports on all routes" do
    expect(redis).to receive(:rpush).twice

    middleware = Rack::Inspector.new(default_app, redis: redis, match_all: true)
    middleware.call env_for("http://foobar.com/")
    middleware.call env_for("http://foobar.com/hello")
  end
end