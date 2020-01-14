require "spec_helper"
require "chef/telemetry/decision"
require "tmpdir"
require "logger"

# This should probably be in the CI script, not here
ENV["CI_TELEMETRY_PROMPT_TIMEOUT"] = "1"

RSpec.describe Chef::Telemetry::Decision do
  it "has a version number" do
    expect(Chef::Telemetry::VERSION).not_to be nil
  end

  let(:logger) { l = Logger.new(STDERR); l.level = Logger::ERROR; l }
  let(:output) do
    buffer = StringIO.new
    allow(buffer).to receive(:isatty).and_return(true)
    buffer
  end
  let(:input) { STDIN }
  let(:opts) { { logger: logger, output: output, input: input } }
  let(:dec) { Chef::Telemetry::Decision.new(opts) }

  def check_option_behavior(test_params = { should_be_enabled: false, should_persist: false, should_prompt: false } )
    Dir.mktmpdir do |dir|

      dec.file_decision.local_dir = dir
      dec.check_and_persist(dir)

      # Branch here for nice(r) error messages
      expect(dec.enabled).to be true if test_params[:should_be_enabled]
      expect(dec.enabled).to be false unless test_params[:should_be_enabled]

      expect(dec.persisted?).to be true if test_params[:should_persist]
      expect(dec.persisted?).to be false unless test_params[:should_persist]

      expect(output.string).to include "https://www.chef.io/privacy-policy/" if test_params[:should_prompt]
      expect(output.string).to be_empty unless test_params[:should_prompt]

    end
  end

  describe "#check_and_persist" do
    describe "when the user expresses intent as an environment variable" do
      let(:env_dec) { instance_double(Chef::Telemetry::Decision::Environment) }
      before do
        expect(Chef::Telemetry::Decision::Environment).to receive(:new).and_return(env_dec)

        # Default all mock decisions to false
        allow(env_dec).to receive(:opt_out?).and_return(false)
        allow(env_dec).to receive(:opt_out_no_persist?).and_return(false)
        allow(env_dec).to receive(:opt_in?).and_return(false)
        allow(env_dec).to receive(:opt_in_no_persist?).and_return(false)
      end

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
          check_option_behavior(should_be_enabled: false, should_prompt: true)
        end
      end
    end

    describe "when the user expresses intent interactively" do
      describe "when the user opts in" do
        let(:input) { StringIO.new("y\n") }
        before do
          allow(dec).to receive(:persisted?).and_return(true)
        end
        it "links to the data policy and opts in and persists" do
          check_option_behavior(
            should_be_enabled: true,
            should_prompt: true,
            should_persist: true
          )
        end
      end
      describe "when the user opts out" do
        let(:input) { StringIO.new("n\n") }
        before do
          allow(dec).to receive(:persisted?).and_return(true)
        end
        it "links to the data policy and opts out and persists" do
          check_option_behavior(
            should_be_enabled: false,
            should_prompt: true,
            should_persist: true
          )
        end
      end
      describe "when the user does not answer" do
        before do
          allow(dec).to receive(:persisted?).and_return(false)
        end
        it "links to the data policy and opts out and does not persist" do
          check_option_behavior(
            should_be_enabled: false,
            should_prompt: true,
            should_persist: false
          )
        end
      end
    end

    describe "when the user expresses intent via a CLI arg" do
      let(:arg_dec) { instance_double(Chef::Telemetry::Decision::Argument) }

      before do
        expect(Chef::Telemetry::Decision::Argument).to receive(:new).and_return(arg_dec)

        # Default all mock decisions to false
        allow(arg_dec).to receive(:enable?).and_return(false)
        allow(arg_dec).to receive(:disable?).and_return(false)
      end

      describe "when the arg is to enable telemetry" do
        before { allow(arg_dec).to receive(:enable?).and_return(true) }
        it "enables telemetry silently and does not persist" do
          check_option_behavior(
            should_be_enabled: true,
            should_prompt: false,
            should_persist: false
          )
        end
      end
      describe "when the arg is to disable telemetry" do
        before { allow(arg_dec).to receive(:disable?).and_return(true) }
        it "disables telemetry silently and does not persist" do
          check_option_behavior(
            should_be_enabled: false,
            should_prompt: false,
            should_persist: false
          )
        end
      end
    end
  end
end
