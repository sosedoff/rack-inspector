module Rack
  class Inspector
    class Payload
      def initialize(middleware, request, status, headers, body)
        @middleware = middleware
        @request    = request
        @status     = status
        @headers    = headers
        @body       = body
      end

      def to_hash
        {
          id:             SecureRandom.uuid,
          app:            @middleware.name,
          host:           @middleware.hostname,
          request_method: @request.request_method,
          path:           @request.path_info,
          status:         @status,
          timestamp:      Time.now.utc,
          request:        request_hash,
          response:       response_hash
        }
      end

      def to_json
        @json ||= JSON.dump(to_hash)
      end

      private

      def request_hash
        {
          query_string:   @request.query_string,
          params:         @request.params,
          body:           @request.body.read,
          env:            select_env(@request.env)
        }
      end

      def response_hash
        {
          status:  @status,
          headers: @headers,
          body:    response_body(@body)
        }
      end

      def select_env(env)
        env.select { |_,v| v.kind_of?(String) }
      end

      def response_body(body)
        if body.respond_to?(:map)
          body.map(&:to_s).join
        else
          body.to_s
        end
      end
    end
  end
end