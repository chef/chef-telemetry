require "net/http"
require "json"
require "concurrent"

class Chef
  class Telemetry
    class Client
      include Concurrent::Async

      TELEMETRY_ENDPOINT = "https://telemetry.chef.io".freeze

      attr_reader :http
      def initialize(endpoint = TELEMETRY_ENDPOINT)
        super()
        @http = Net::HTTP.new(endpoint)
        @http.start
      end

      def fire(event)
        req = Net::HTTP::Post.new("/events")
        req["Content-Type"] = "application/json"
        req.body = JSON.dump(event)
        # TODO: @cwolfe use response and at least debug log status
        http.request req
      end
    end

    class OptOutClient
      def fire(_); end
    end
  end
end
