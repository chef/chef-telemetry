require "chef-config/path_helper"
require "chef-config/windows"
require "logger"
require_relative "decision/environment"
require_relative "decision/file"

# Decision allows us to inspect whether the user has made a decision to opt in or opt out of telemetry.
class Chef
  class Telemetry
    class Decision
      OPT_OUT_FILE = "telemetry_opt_out".freeze
      OPT_IN_FILE = "telemetry_opt_in".freeze

      def initialize(opts = {})
        @config = opts
        @env_decision = Decision::Environment.new(ENV)
        @file_decision = Decision::File.new(opts)
      end

      #
      # Methods for obtaining consent from the user.
      #
      def check_and_persist
        enabled = (@env_decision.opt_in? && !@env_decision.opt_out?) ||
                    @file_decision.opt_in?
        enabled
      end

      def self.check_and_persist(opts = {})
        new(opts)
      end

      #
      # Predicates for determining status of opt-in.
      #
      class << self
        def opt_out?
          # We check that the user has made a decision so that we can have a default setting for robots
          user_opted_out? || env_opt_out? || local_opt_out? || !made?
        end

        # Check whether the user has made an explicit decision on their participation.
        def made?
          user_opted_in? || user_opted_out?
        end

        def user_opted_out?
          File.exist?(File.join(home, OPT_OUT_FILE))
        end

        def user_opted_in?
          File.exist?(File.join(home, OPT_IN_FILE))
        end

        def env_opt_out?
          ENV.key?("CHEF_TELEMETRY_OPT_OUT")
        end
      end
    end
  end
end # Chef
