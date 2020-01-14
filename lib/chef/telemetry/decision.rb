require "chef-config/path_helper"
require "chef-config/windows"
require "logger"
require "forwardable"
require_relative "decision/environment"
require_relative "decision/file"
require_relative "decision/prompt"

# Decision allows us to inspect whether the user has made a decision to opt in or opt out of telemetry.
class Chef
  class Telemetry
    class Decision
      extend Forwardable

      attr_reader :config, :enabled, :env_decision, :file_decision, :prompt_decision, :logger

      def initialize(opts = {})
        @config = opts
        @logger = opts[:logger] || Logger.new(opts.key?(:output) ? opts[:output] : STDERR)
        @config[:output] ||= STDOUT
        config[:logger] = logger

        # This is the whole point - whether telemetry shoud be enabled in this
        # runtime invocation. Start by assuming no.
        @enabled = false

        # The various things that have a say in whether telemetry should be enabled.
        @env_decision = Decision::Environment.new(ENV)
        @file_decision = Decision::File.new(config)
        @prompt_decision = Decision::Prompt.new(config)
      end

      #
      # Methods for obtaining consent from the user.
      #
      def check_and_persist(dir) # TODO - What default, if any, for dir?
        file_decision.local_dir = dir

        # If a non-persisting decision is made by env, only set runtime decision
        logger.debug "Telemetry decision examining ephemeral ENV checks"
        return @enabled = true if @env_decision.opt_in_no_persist?
        return @enabled = false if @env_decision.opt_out_no_persist?

        # Check to see if a persistent decision is made by env but not yet persisted
        #  then persist it and set runtime decision
        logger.debug "Telemetry decision examining persistent ENV checks"
        if env_decision.opt_in?
          file_decision.persist(true, dir) if !persisted? || file_decision.opt_out?
          return @enabled = true
        elsif env_decision.opt_out?
          file_decision.persist(false, dir) if !persisted? || file_decision.opt_in?
          return @enabled = false
        end

        # If a decision has been made by file, read from disk and set runtime decision
        logger.debug "Telemetry decision examining file checks"
        if persisted?
          return @enabled = true if file_decision.opt_in?
          return @enabled = false if file_decision.opt_out?
        end

        # Lowest priority is to interactively prompt if we have a TTY
        if config[:output].isatty
          logger.debug "Telemetry decision - detected TTY, prompting..."
          return @enabled = prompt_decision.prompt(dir, file_decision)
        end

        # Otherwise no decision has been made, default to runtime opt-out
        logger.debug "Telemetry decision - no decision, defaulting to opt-out"
        @enabled = false
      end

      def self.check_and_persist(opts = {})
        new(opts).check_and_persist
      end

      #
      # Predicates for determining status of opt-in.
      #
      def_delegator :file_decision, :persisted?

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
