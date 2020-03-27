#
# Copyright:: Copyright (c) 2018 Chef Software Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require "spec_helper"
require "chef/telemeter"
require "logger"

RSpec.describe Chef::Telemeter do
  subject { Chef::Telemeter.instance }
  let(:host_platform) { "linux" }
  let(:enabled_flag) { false }
  let(:dev_mode) { false }
  let(:logger) { l = Logger.new(STDERR); l.level = Logger::WARN; l }
  let(:config) do
    {
      payload_dir: "/tmp/telemeter-test/paylaods",
      session_file: "/tmp/telemeter-test/TELEMETRY_SESSION_ID",
      installation_identifier_file: "/etc/chef/chef_guid",
      enabled: enabled_flag,
      dev_mode: dev_mode,
      logger: logger,
    }
  end

  before do
    allow(subject).to receive(:host_platform).and_return host_platform
    allow(subject).to receive(:config).and_return config
  end

  # TODO
  #
  context "::setup" do
  end

  context "#commit" do
    context "when telemetry is enabled" do
      let(:enabled_flag) { true }

      it "writes events out and clears the queue" do
        subject.capture(:test)
        expect(subject.pending_event_count).to eq 1
        expect(subject).to receive(:convert_events_to_session)
        expect(subject).to receive(:write_session)

        subject.commit
        expect(subject.pending_event_count).to eq 0
      end
    end

    context "when telemetry is disabled" do
      let(:enabled_flag) { false }
      it "does not write any events and clears the queue" do
        subject.capture(:test)
        expect(subject.pending_event_count).to eq 1
        expect(subject).to_not receive(:convert_events_to_session)

        subject.commit
        expect(subject.pending_event_count).to eq 0
      end
    end
  end

  context "::enabled?" do
    context "when config value is enabled" do
      let(:enabled_flag) { true }
      it "returns true" do
        expect(subject.enabled?).to eq true
      end
    end

    context "when config value is disabled" do
      let(:enabled_flag) { false }
      it "returns false" do
        expect(subject.enabled?).to eq false
      end
    end
  end

  context "#timed_run_capture" do
    it "invokes timed_capture with run data" do
      expected_data = { arguments: [ "arg1" ] }
      expect(subject).to receive(:timed_capture)
        .with(:run, expected_data)
      subject.timed_run_capture(["arg1"])
    end
  end

  context "#timed_capture" do
    let(:runner) { double("capture_test") }
    before do
      expect(subject.pending_event_count).to eq 0
    end

    it "runs the requested thing and invokes #capture with duration" do
      expect(runner).to receive(:do_it)
      expect(subject).to receive(:capture) do |name, data|
        expect(name).to eq(:do_it_test)
        expect(data[:duration]).to be > 0.0
      end
      subject.timed_capture(:do_it_test) do
        runner.do_it
      end
    end
  end

  context "#capture" do
    before do
      expect(subject.pending_event_count).to eq 0
    end
    it "adds the captured event to the session" do
      subject.capture(:test, {})
      expect(subject.pending_event_count) == 1
    end
  end

  context "#make_event_payload" do
    before do
      allow(subject).to receive(:installation_id).and_return "0000"
    end

    it "adds expected properties" do
      payload = subject.make_event_payload(:run, { hello: "world" })
      expected_payload = {
        event: :run,
        properties: {
          installation_id: "0000",
          run_timestamp: subject.run_timestamp,
          host_platform: host_platform,
          event_data: { hello: "world" },
        },
      }
      expect(payload).to eq expected_payload
    end
  end
end
