require "json"
require "redis"
require "rack"
require "securerandom"

require "rack/inspector/version"

module Rack
  class Inspector
    def initialize(app, options={})
      @app       = app
      @hostname  = `hostname`.strip
      @name      = ::File.basename(::File.dirname(__FILE__))

      @match_all = options[:match_all] == true
      @routes    = options[:routes] || []
      @redis     = options[:redis] || Redis.new
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

    def report?(request)
      if @match_all
        true
      else
        @routes.select { |r| r =~ request.path_info }.size > 0
      end
    end

    def build_payload(request, status, headers, body)
      {
        id:             SecureRandom.uuid,
        app:            @name,
        host:           @hostname,
        request_method: request.request_method,
        path:           request.env['REQUEST_URI'],
        status:         status,
        timestamp:      Time.now.utc,

        request: {
          query_string:   request.query_string,
          params:         request.params,
          body:           request.body.read,
          env:            select_env(request.env)
        },

        response: {
          status:  status,
          headers: headers,
          body:    response_body(body)
        }
      }
    end

    def response_body(body)
      if body.respond_to?(:map)
        body.map(&:to_s).join
      else
        body.to_s
      end
    end

    def deliver_payload(payload)
      @redis.rpush("reports", JSON.dump(payload))
    end

    def select_env(env)
      env.select { |_,v| v.kind_of?(String) }
    end
  end
end