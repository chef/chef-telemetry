require "spec_helper"

include Chef # TODO: remove

RSpec.describe Telemetry::Event do
  let(:product) { "unit" }
  let(:product_version) { "1.0.0" }
  let(:install_context) { "omnibus" }
  let(:session_id) { "A-NEW-UUID" }
  let(:session) { double("Session", id: session_id) }
  let(:origin) { "rspec" }

  let(:event) do
    {
      canteloupe: "melon",
      properties: {},
    }
  end

  let(:timestamp) { "2017-09-18T15:34:58Z" }

  before do
    allow_any_instance_of(Time).to receive(:strftime).with("%FT%TZ").and_return timestamp
  end

  describe "#prepare" do
    subject do
      e = Telemetry::Event.new(product, session, origin, install_context, product_version)
      e.prepare(event)
    end

    it "sets the session id" do
      expect(subject[:session_id]).to eql(session_id)
    end

    it "sets the product" do
      expect(subject[:product]).to eql(product)
    end

    it "time stamps the event" do
      expect(subject[:timestamp]).to eql(timestamp)
    end

    it "includes the payload" do
      expect(subject[:payload]).to eql(event)
    end

    it "time stamps the payload" do
      expect(subject[:payload][:properties][:timestamp]).to eql(timestamp)
    end

  end
end
