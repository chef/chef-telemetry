require "http"
require "concurrent"

class Chef
  class Telemetry
    class Client
      include Concurrent::Async

      TELEMETRY_ENDPOINT = "https://telemetry.chef.io".freeze

      attr_reader :http, :logger

      def initialize(logr = nil, endpoint = TELEMETRY_ENDPOINT)
        super()
        @http = HTTP.persistent(endpoint)
        @logger = logr || Logger.new(STDERR)
      end

      def fire(event)
        response = http.post("/events", json: event)
        logger.debug("Have HTTP code #{response.code} for telemetry entry")
        response.flush
      end
    end

    class OptOutClient
      def fire(_); end
    end
  end
end
