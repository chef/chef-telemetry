require "spec_helper"

RSpec.describe Chef::Telemetry do
  let(:payload) do
    {
      properties: {},
    }
  end
  let(:env) { {} }

  describe "#client" do
    let(:endpoint) { "https:://my.telemetry.endpoint" }
    before do
      stub_const("ENV", env)
    end

    describe "creates a new client" do
      it "with the default endpoint" do
        expect(Chef::Telemetry::Client).to receive(:new).with(Chef::Telemetry::Client::TELEMETRY_ENDPOINT)
        subject.client
      end

      it "using an environment key" do
        env["CHEF_TELEMETRY_ENDPOINT"] = endpoint
        expect(Chef::Telemetry::Client).to receive(:new).with(endpoint)
        subject.client
      end
    end
  end

  describe "opted in" do
    let(:default_endpoint) { "https://telemetry.chef.io" }

    before do
      expect(Chef::Telemetry::Decision).to receive(:opt_out?).and_return(false)
      net_http_mock = double(Net::HTTP, 'use_ssl=': true, start: true, request: {})
      uri = URI(default_endpoint)
      allow(Net::HTTP).to receive(:new).with(uri.host, uri.port).and_return(net_http_mock)
    end

    it "sends an event" do
      expect(subject.event).to receive(:prepare).with(payload).and_call_original
      expect(subject.deliver(payload)).to be_truthy
    end
  end

  describe "opted out" do
    before do
      expect(Chef::Telemetry::Decision).to receive(:opt_out?).and_return(true)
    end

    it "doesn't send an event" do
      expect(subject).to_not receive(:event)
      subject.deliver(payload)
    end
  end
end
