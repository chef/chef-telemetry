require "spec_helper"

RSpec.describe Chef::Telemetry do
  let(:payload) do
    {
      properties: {},
    }
  end
  let(:env) { {} }
  let(:logger) {
    l = Logger.new(STDERR)
    l.level = Logger::WARN
    l
  }

  describe "#client" do
    let(:endpoint) { "https:://my.telemetry.endpoint" }
    before do
      stub_const("ENV", env)
    end

    describe "creates a new client" do
      it "with the default endpoint" do
        expect(Chef::Telemetry::Client).to receive(:new).with(subject.logger, Chef::Telemetry::Client::TELEMETRY_ENDPOINT)
        subject.client
      end

      it "using an environment key" do
        env["CHEF_TELEMETRY_ENDPOINT"] = endpoint
        expect(Chef::Telemetry::Client).to receive(:new).with(subject.logger, endpoint)
        subject.client
      end
    end
  end

  describe "enabled" do
    before do
      expect(Chef::Telemeter).to receive(:enabled?).and_return(true)
      subject.logger.level = Logger::WARN
    end

    it "sends an event" do
      expect(subject.event).to receive(:prepare).with(payload).and_call_original
      expect(subject.deliver(payload)).to be_truthy
    end
  end

  describe "disabled" do
    before do
      expect(Chef::Telemeter).to receive(:enabled?).and_return(false)
    end

    it "doesn't send an event" do
      expect(subject).to_not receive(:event)
      subject.deliver(payload)
    end
  end
end
