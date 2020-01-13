require "spec_helper"
require "chef/telemetry/decision"
require "tmpdir"
require "logger"

RSpec.describe Chef::Telemetry::Decision do
  it "has a version number" do
    expect(Chef::Telemetry::VERSION).not_to be nil
  end

  let(:logger) { l = Logger.new(STDERR); l.level = Logger::ERROR; l }
  let(:opts) { { logger: logger } }
  let(:dec) { Chef::Telemetry::Decision.new(opts) }

  def check_option_behavior(test_params = { should_be_enabled: false, should_persist: false } )
    Dir.mktmpdir do |dir|

      dec.file_decision.local_dir = dir
      dec.check_and_persist(dir)

      # Branch here for nice(r) error messages
      expect(dec.enabled).to be true if test_params[:should_be_enabled]
      expect(dec.enabled).to be false if !test_params[:should_be_enabled]

      expect(dec.persisted?).to be true if test_params[:should_persist]
      expect(dec.persisted?).to be false if !test_params[:should_persist]
    end
  end

  describe "#check_and_persist" do
    let(:env_dec) { instance_double(Chef::Telemetry::Decision::Environment) }

    before do
      expect(Chef::Telemetry::Decision::Environment).to receive(:new).and_return(env_dec)

      # Default all mock decisions to false
      allow(env_dec).to receive(:opt_out?).and_return(false)
      allow(env_dec).to receive(:opt_out_no_persist?).and_return(false)
      allow(env_dec).to receive(:opt_in?).and_return(false)
      allow(env_dec).to receive(:opt_in_no_persist?).and_return(false)
    end

    describe "when the user expresses intent as an environment variable" do
      describe "when intent is opt-in without persistence" do
        before { allow(env_dec).to receive(:opt_in_no_persist?).and_return(true) }
        it "opts in silently without persistence" do
          check_option_behavior(should_be_enabled: true)
        end
      end

      describe "when intent is opt-out with no persistence" do
        before { allow(env_dec).to receive(:opt_out_no_persist?).and_return(true) }
        it "opts out silently without persistence" do
          check_option_behavior(should_be_enabled: false)
        end
      end

      describe "when intent is opt-in with persistance" do
        before do
          allow(env_dec).to receive(:opt_in?).and_return(true)
          allow(dec).to receive(:persisted?).and_return(true)
        end
        it "opts in silently and persists to disk" do
          check_option_behavior(should_be_enabled: true, should_persist: true)
        end
      end

      describe "when intent is opt-out with persistance" do
        before do
          allow(env_dec).to receive(:opt_out?).and_return(true)
          allow(dec).to receive(:persisted?).and_return(true)
        end
        it "opts out silently and persists to disk" do
          check_option_behavior(should_be_enabled: false, should_persist: true)
        end
      end

    end

    describe "when the user expresses intent as a file" do

      describe "when intent is opt-in" do
        before do
          allow(dec).to receive(:persisted?).and_return(true)
          allow(dec.file_decision).to receive(:contents).and_return({ enabled: true })
        end
        it "opts in silently" do
          check_option_behavior(should_be_enabled: true, should_persist: true)
        end
      end

      describe "when intent is opt-out" do
        before do
          allow(dec).to receive(:persisted?).and_return(true)
          allow(dec.file_decision).to receive(:contents).and_return({ enabled: false })
        end
        it "opts out silently" do
          check_option_behavior(should_be_enabled: false, should_persist: true)
        end
      end

      describe "when no file is present" do
        before do
          allow(dec).to receive(:persisted?).and_return(false)
          allow(dec.file_decision).to receive(:contents).and_return(nil)
        end
        it "opts out" do
          check_option_behavior(should_be_enabled: false)
        end
      end
    end
  end
end
