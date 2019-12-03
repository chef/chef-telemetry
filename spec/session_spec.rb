require "spec_helper"

RSpec.describe Chef::Telemetry::Session do
  let(:home) { "/Users/chef_user" }
  let(:session_path) { "/Users/chef_user/.chef/TELEMETRY_SESSION_ID" }
  let(:new_uuid) { "NEW-UUID" }
  let(:existing_uuid) { "OLD-UUID" }
  let(:stat_mock) { double("FileStat") }
  let(:write_mock) { double("File") }

  before do
    allow(ChefConfig::PathHelper).to receive(:home).with(".chef").and_return(File.join(home, ".chef"))
    allow(SecureRandom).to receive(:uuid).and_return(new_uuid)
    expect(FileUtils).to receive(:touch).with(session_path).and_return true
    allow(FileUtils).to receive(:mkdir_p).with(File.dirname(session_path)).and_return true

    allow(File).to receive(:stat).with(session_path).and_return(stat_mock)
    allow(File).to receive(:open).with(session_path, "w").and_yield(write_mock)
  end

  describe "#id" do
    it "creates a new ID" do
      expect(File).to receive(:file?).with(session_path).and_return(false)
      expect(write_mock).to receive(:write).with(new_uuid)
      expect(subject.id).to eql(new_uuid)
    end

    it "returns a live ID" do
      expect(File).to receive(:file?).with(session_path).and_return(true)
      expect(stat_mock).to receive(:mtime).and_return(Time.now)
      expect(File).to receive(:read).with(session_path).and_return(existing_uuid)
      expect(subject.id).to eql(existing_uuid)
    end

    it "invalidates an old session" do
      expect(File).to receive(:file?).with(session_path).and_return(true)
      expect(stat_mock).to receive(:mtime).and_return(Time.now - 700)
      expect(write_mock).to receive(:write).with(new_uuid)
      expect(subject.id).to eql(new_uuid)
    end
  end
end
