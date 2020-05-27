require "spec_helper"

RSpec.describe Chef::Telemetry::OptOutClient do
  it "should do nothing" do
    expect(subject.fire("fire!")).to be nil
  end
end

RSpec.describe Chef::Telemetry::Client do

  let(:telemetry_endpoint) { "https://my.telemetry.endpoint" }
  let(:event) { {} }

  it "initializes the http client" do
    net_http_mock = double(Net::HTTP)
    expect(Net::HTTP).to receive(:new).with(telemetry_endpoint).and_return(net_http_mock)
    expect(net_http_mock).to receive(:start)
    Chef::Telemetry::Client.new(telemetry_endpoint)
  end

  it "sends an event" do
    response_mock = double(Net::HTTPResponse, status: 200)
    expect(subject.http).to receive(:request).with(instance_of(Net::HTTP::Post)).and_return(response_mock)
    subject.fire(event)
  end
end
