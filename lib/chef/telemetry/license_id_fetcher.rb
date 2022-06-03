require "chef-config/path_helper"
require "chef-config/windows"
require "logger"
require "forwardable"

require_relative "license_id_fetcher/argument"
require_relative "license_id_fetcher/environment"
require_relative "license_id_fetcher/file"
require_relative "license_id_fetcher/prompt"

# LicenseIdFetcher allows us to inspect obtain the license ID from the user in a variety of ways.
class Chef
  class Telemetry
    class LicenseIdFetcher

      class LicenseIdNotFetchedError < Exception
      end

      extend Forwardable

      attr_reader :config, :license_id, :arg_fetcher, :env_fetcher, :file_fetcher, :prompt_fetcher, :logger
      def initialize(opts = {})
        @config = opts
        @logger = opts[:logger] || Logger.new(opts.key?(:output) ? opts[:output] : STDERR)
        @config[:output] ||= STDOUT
        config[:logger] = logger
        config[:dir] = opts[:dir]

        # This is the whole point - to obtain the license ID.
        @license_id = nil

        # The various things that have a say in fetching the license ID.
        @arg_fetcher = LicenseIdFetcher::Argument.new(ARGV)
        @env_fetcher = LicenseIdFetcher::Environment.new(ENV)
        @file_fetcher = LicenseIdFetcher::File.new(config)
        @prompt_fetcher = LicenseIdFetcher::Prompt.new(config)
      end

      #
      # Methods for obtaining consent from the user.
      #
      def fetch_and_persist(product, version)

        # TODO: handle non-persistent cases

        # If a fetch is made by CLI arg, persist and return
        logger.debug "Telemetry license ID fetcher examining CLI arg checks"
        if @license_id = @arg_fetcher.fetch
          file_fetcher.persist(license_id, product, version)
          return license_id
        end

        # If a fetch is made by ENV, persist and return
        logger.debug "Telemetry license ID fetcher examining ENV checks"
        if @license_id = @env_fetcher.fetch
          file_fetcher.persist(license_id, product, version)
          return license_id
        end

        # If it has previously been fetched and persisted, read from disk and set runtime decision
        logger.debug "Telemetry license ID fetcher examining file checks"
        if file_fetcher.persisted?
          return @license_id = file_fetcher.fetch
        end

        # Lowest priority is to interactively prompt if we have a TTY
        if config[:output].isatty
          logger.debug "Telemetry license ID fetcher - detected TTY, prompting..."
          if @license_id = prompt_fetcher.fetch
            file_fetcher.persist(license_id, product, version)
            return license_id
          end
        end

        # Otherwise nothing was able to fetch a license. Throw an exception.
        logger.debug "Telemetry license ID fetcher - no license ID able to be fetched."
        raise LicenseIdNotFetchedError.new("Unable to obtain a License ID.")

      end

      # Assumes fetch_and_persist has been called and succeeded
      def fetch(_product, _version)
        @arg_fetcher.fetch || @env_fetcher.fetch || @file_fetcher.fetch
      end

      def self.fetch_and_persist(product, version, opts)
        new(opts).fetch_and_persist(product, version)
      end

      def self.fetch(product, version, opts)
        new(opts).fetch(product, version)
      end

    end
  end
end # Chef
