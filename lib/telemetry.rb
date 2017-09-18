require "telemetry/client"
require "telemetry/decision"
require "telemetry/event"
require "telemetry/session"
require "telemetry/version"

class Telemetry
  attr_accessor :product, :origin
  def initialize(product: nil, origin: "command-line")
    @product = product
    @origin = origin
  end

  def deliver(data = {})
    unless opt_out?
      payload = event.prepare(data)
      client.async.fire(payload)
    end
  end

  def event
    @event ||= Event.new(product, session, origin)
  end

  def session
    @session ||= Session.new
  end

  def opt_out?
    @opt_out ||= Decision.opt_out?
  end

  def client
    endpoint = ENV.fetch("CHEF_TELEMETRY_ENDPOINT", Client::TELEMETRY_ENDPOINT)
    @client ||= Client.new(endpoint)
  end
end
