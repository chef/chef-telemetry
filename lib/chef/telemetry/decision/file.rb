
require "chef-config/windows"
require "chef-config/path_helper"

class Chef
  class Telemetry
    class Decision

      # Represents a telemetry opt-in or out recorded on disk.
      class File
        OPT_OUT_FILE = "telemetry_opt_out".freeze
        OPT_IN_FILE = "telemetry_opt_in".freeze

        def initialize(opts)
          @opts = opts
        end

        # Checks for the existence of a decision file, and returns true if found
        def opt_in?
          !!seek(OPT_IN_FILE)
        end

        # Checks for the existence of a decision file, and retruns true if found
        def opt_out?
          !!seek(OPT_OUT_FILE)
        end

        # Writes a decision file to disk in the location specified,
        # with the content given
        def persist(decision, dir, content = {})
          # TODO
        end

        private

        # Look for a decsion file in several locations.
        def seek(type)
          candidates = []

          # Include the user home directory ~/.chef
          candidates << ChefConfig::PathHelper.home(".chef/#{type}")

          # Include /etc/chef if on unix-like
          candidates << "/etc/chef/#{type}" unless ChefConfig.windows?

          # Seek up from current directory
          current_path = working_directory.split(::File::SEPARATOR)
          (current_path.length - 1).downto(0) do |i|
            candidates << ::File.join(current_path[0..i], ".chef", type)
          end

          candidates.detect { |c| ::File.exist?(c) }
        end

        def working_directory
          (ChefConfig.windows? ? ENV["CD"] : ENV["PWD"]) || Dir.pwd
        end

      end
    end
  end
end
