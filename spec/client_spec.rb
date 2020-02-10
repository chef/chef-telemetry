require "spec_helper"

RSpec.describe Chef::Telemetry::OptOutClient do
  it "should do nothing" do
    expect(subject.fire("fire!")).to be nil
  end
end

RSpec.describe Chef::Telemetry::Client do

  let(:telemetry_endpoint) { "https://my.telemetry.endpoint" }
  let(:logger) {
    l = Logger.new(STDERR)
    l.level = Logger::WARN
    l
  }
  let(:event) { {} }
  let(:http_mock) { double(HTTP, flush: true) }

  it "initializes the http client" do
    expect(HTTP).to receive(:persistent).with(telemetry_endpoint)
    Chef::Telemetry::Client.new(logger, telemetry_endpoint)
  end

  it "sends an event" do
    expect(http_mock).to receive(:code).and_return("200")
    expect(subject.logger).to receive(:debug)
    expect(subject.http).to receive(:post).with("/events", hash_including(json: event)).and_return(http_mock)
    subject.fire(event)
  end
end
