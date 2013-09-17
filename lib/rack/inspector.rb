require "json"
require "redis"
require "rack"
require "securerandom"

require "rack/inspector/version"
require "rack/inspector/payload"

module Rack
  class Inspector
    attr_reader :name, :hostname, :routes

    def initialize(app, options={})
      @app       = app
      @hostname  = options[:hostname] || `hostname`.strip
      @name      = ::File.basename(::File.dirname(__FILE__))
      @match_all = options[:match_all] == true
      @routes    = ([options[:match]] || []).flatten.compact.uniq
      @redis     = options[:redis] || Redis.new
      @redis_key = options[:key] || "reports"

      @routes.each do |r|
        unless valid_route?(r)
          raise ArgumentError, "Non-regular expessions in match"
        end
      end
    end

    def call(env)
      request = Rack::Request.new(env)

      # Call application
      status, headers, body = @app.call(env)

      if report?(request)
        payload = build_payload(request, status, headers, body)
        deliver_payload(payload)
      end

      # Return original data
      [status, headers, body]
    end

    private

    def valid_route?(val)
      val.kind_of?(Regexp)
    end

    def report?(request)
      if @match_all
        true
      else
        @routes.select { |r| r =~ request.path_info }.size > 0
      end
    end

    def build_payload(request, status, headers, body)
      Rack::Inspector::Payload.new(
        self,
        request, status, headers, body
      )
    end

    def deliver_payload(payload)
      @redis.rpush(@redis_key, JSON.dump(payload.to_hash))
    end
  end
end