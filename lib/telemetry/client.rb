require "http"
require "concurrent"

class Telemetry
  class Client
    include Concurrent::Async

    TELEMETRY_ENDPOINT = "https://telemetry.chef.io".freeze

    attr_reader :http
    def initialize(endpoint = TELEMETRY_ENDPOINT)
      super()
      @http = HTTP.persistent(endpoint)
    end

    def fire(event)
      http.post("/events", json: event).flush
    end
  end

  class OptOutClient
    def fire(_); end
  end
end
