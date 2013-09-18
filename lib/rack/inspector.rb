require "json"
require "redis"
require "rack"
require "securerandom"

require "rack/inspector/version"
require "rack/inspector/payload"

module Rack
  class Inspector
    attr_reader :name, :hostname, :routes, :statuses

    def initialize(app, options={})
      @app       = app
      @hostname  = options[:hostname] || `hostname`.strip
      @name      = options[:name]     || ::File.basename(Dir.pwd)

      load_options(options)
    end

    def call(env)
      request = Rack::Request.new(env)

      # Call application
      status, headers, body = @app.call(env)

      if report?(request, status)
        payload = build_payload(request, status, headers, body)
        deliver_payload(payload)
      end

      # Return original data
      [status, headers, body]
    end

    def deliver_payload(payload)
      @redis.rpush(@redis_key, payload.to_json)
      @redis.publish(@redis_key, payload.to_json)
    end

    private

    def load_options(options)
      @routes    = parse_array_option(options[:path])
      @statuses  = parse_array_option(options[:status])
      @methods   = parse_array_option(options[:method])

      @routes.each do |r|
        unless valid_route?(r)
          raise ArgumentError, "Non-regular expessions in path"
        end
      end

      # Assign Redis options
      @redis     = options[:redis] || redis_from_url || Redis.new
      @redis_key = options[:key] || "reports"
    end

    def parse_array_option(val)
      [val].flatten.compact.uniq
    end

    def redis_from_url
      if ENV["REDIS_INSPECT_URL"]
        uri = URI.parse(ENV["REDIS_INSPECT_URL"])
        Redis.new(host: uri.host, port: uri.port, password: uri.password)
      end
    end

    def valid_route?(val)
      val.kind_of?(Regexp)
    end

    def report?(request, status)
      path_matches?(request.path_info) &&
      method_matches?(request.request_method) &&
      status_matches?(status)
    end

    def path_matches?(path)
      @routes.any? ? @routes.select { |r| r =~ path }.size > 0 : true
    end

    def method_matches?(method)
      @methods.any? ? @methods.include?(method) : true
    end

    def status_matches?(code)
      @statuses.any? ? @statuses.include?(code) : true
    end

    def build_payload(request, status, headers, body)
      Rack::Inspector::Payload.new(
        self,
        request, status, headers, body
      )
    end
  end
end