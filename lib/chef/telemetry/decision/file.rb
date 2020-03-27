
require "chef-config/windows"
require "chef-config/path_helper"
require "yaml"
require "date"

class Chef
  class Telemetry
    class Decision

      # Represents a telemetry opt-in or out recorded on disk.
      class File
        DECISION_FILE = "telemetry_options.yaml".freeze

        attr_reader :logger, :contents, :location
        attr_accessor :local_dir # Optional local path to use to seek

        def initialize(opts)
          @opts = opts
          @logger = opts[:logger]
          @contents_ivar = nil
          @location = nil
        end

        # Checks for the existence of a decision file, and returns true if the decision was to enable.
        # Returns false if the decision was not made or if it was not enabled.
        def opt_in?
          read_decision_file
          !contents.nil? && contents[:enabled]
        end

        # Checks for the existence of a decision file, and retruns true if the decision was to disable.
        # Returns false if the decision was not made or if it was enabled.
        def opt_out?
          read_decision_file
          !contents.nil? && !contents[:enabled]
        end

        # Writes a decision file to disk in the location specified,
        # with the content given.
        # @return Array of Errors
        def persist(decision, dir, content = {})
          content[:decision_time] = DateTime.now.to_s
          content[:enabled] = decision
          @contents = content

          begin
            msg = "Could not create directory for telemetry optin/out decision #{dir}"
            FileUtils.mkdir_p(dir)
            msg = "Could not write telemetry optin/out decision file #{dir}/#{DECISION_FILE}"
            ::File.write("#{dir}/#{DECISION_FILE}", YAML.dump(content))
            return []
          rescue StandardError => e
            logger.info "#{msg}\n\t#{e.message}"
            logger.debug "#{e.backtrace.join("\n\t")}"
            return [e]
          end
        end

        # Returns true if a decision file exists.
        def persisted?
          !!seek
        end

        def self.default_file_location
          ChefConfig::PathHelper.home(".chef")
        end

        private

        # Look for an *existing* decsion file in several locations.
        def seek
          return location if location

          on_windows = ChefConfig.windows?
          candidates = []

          # Include the user home directory ~/.chef
          candidates << "#{self.class.default_file_location}/#{DECISION_FILE}"
          candidates << "/etc/chef/#{DECISION_FILE}" unless on_windows

          # Include software installation dirs for bespoke downloads.
          # TODO: unlikely these would be writable if decision changes.
          [
            # TODO - get a complete list
            "chef-workstation",
            "inspec",
          ].each do |inst_dir|
            if on_windows
              candidates << "C:/opscode/#{inst_dir}/#{DECISION_FILE}"
            else
              candidates << "/opt/#{inst_dir}/#{DECISION_FILE}"
            end
          end

          # Include local directory if provided. Not usual, but useful for testing.
          candidates << "#{local_dir}/#{DECISION_FILE}" if local_dir

          @location = candidates.detect { |c| ::File.exist?(c) }
        end

        def working_directory
          (ChefConfig.windows? ? ENV["CD"] : ENV["PWD"]) || Dir.pwd
        end

        def read_decision_file
          return contents if contents
          path = seek
          return nil unless path
          @contents ||= YAML.load(::File.read(path))
        end

      end
    end
  end
end
