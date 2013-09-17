module Rack
  class Inspector
    class Payload
      def initialize(request, status, headers, body)
        @hash = {
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

      def to_hash
        @hash
      end

      private

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