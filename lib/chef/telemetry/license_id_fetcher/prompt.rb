# Use same support libraries as license-acceptance
require "tty-prompt"
require "pastel"
require "timeout"
require "chef-config/windows"
require_relative "base"

class Chef
  class Telemetry
    class LicenseIdFetcher
      # Represents fetching a license ID by interactively prompting the user,
      # and possibly querying an API to lookup a new license ID.
      class Prompt < Base

        attr_reader :logger, :output, :input

        PASTEL = Pastel.new
        BORDER = "+---------------------------------------------+".freeze
        YES = PASTEL.green.bold("yes")
        CHECK = PASTEL.green(ChefConfig.windows? ? "√" : "✔")
        X_MARK = PASTEL.red(ChefConfig.windows? ? "x" : "×")
        CIRCLE = PASTEL.green(ChefConfig.windows? ? "O" : "◯")

        def initialize(cfg)
          @logger = cfg[:logger]
          @output = cfg[:output]
          @input = cfg[:input] || STDIN
        end

        def fetch
          logger.debug "Prompting for license ID..."

          output.puts <<~EOM
                      Provide Your License ID

            To access premium content and other special features,
            you will need a Chef License ID.

            If you already have one, you can enter it at the prompt
            on the following screen.

            If you need to get an evaluation or personal use license
            ID, you can get one by providing your email address.

          EOM

          # This first one has a timeout on it
          result = choose_how_to_fetch_license_id

          # Remaining UI interactions do not have timeouts
          case result
          when /enter/i
            return fetch_license_id_by_manual_entry
          when /lookup/i
            return fetch_license_id_by_email_lookup
          when /exit/i
            exit_because_user_chose_not_to_enter
          end
        end

        private

        def choose_how_to_fetch_license_id
          logger.debug("Attempting to request interactive prompt on TTY")
          prompt = TTY::Prompt.new(track_history: false, active_color: :bold, interrupt: :exit, output: output, input: input)
          timeout = ENV["CI_TELEMETRY_PROMPT_TIMEOUT"].nil? ? 60 : ENV["CI_TELEMETRY_PROMPT_TIMEOUT"].to_i
          handle_timeout = ->() {
            prompt.unsubscribe(prompt.reader)
            output.puts "\nPrompt timed out. Exiting without a license ID set."
            return "Exit without setting a License ID"
          }

          # TODO: Test timeout on Windows
          begin
            Timeout.timeout(timeout, PromptTimeout) do
              answer = prompt.select(
                "How would you like to provide a License ID?",
                [
                  "Enter a License ID manually",
                  "Generate or Lookup a License ID based on my email address",
                  "Exit without setting a License ID",
                ]
              )
            end
          rescue PromptTimeout
            return handle_timeout.call
          end

          logger.debug "Saw answer '#{answer}'"
        end

        def fetch_license_id_by_manual_entry
          logger.debug "Prompting for license ID..."

          output.puts <<~EOM
            Enter your License ID.

            A Chef License ID is #{LICENSE_ID_PATTERN_DESC}.

            Enter "q" to quit without entering a Chef License ID.

          EOM

          logger.debug("Attempting to request interactive prompt on TTY")
          prompt = TTY::Prompt.new(track_history: false, active_color: :bold, interrupt: :exit, output: output, input: input)
          answer = prompt.ask("License ID:")
          unless match = answer =~ /^(q|Q)|#{LICENSE_ID_REGEX}$/
            # TODO: this could be more graceful
            puts "Unrecognized License ID format '#{answer}'"
            return fetch_license_id_by_manual_entry
          end

          if match[1] == "q" || match[1] == "Q"
            exit_because_user_chose_not_to_enter
          end

          puts "#{BORDER}"
          return match[2]
        end

        def exit_because_user_chose_not_to_enter
          puts "OK, exiting without setting a License ID..."
          Inspec::UI.new.exit # TODO: consider special exit code here
        end

        def fetch_license_id_by_email_lookup
          logger.debug "Prompting for email..."

          output.puts <<~EOM
            Enter your email address.

            The licensing system will look up your email address and
            if a License ID is already associated with your email, it
            will be set for the future.

            If no License ID is currently associated with your email
            address, a new evaluation License ID will be generated
            and will be set for future use.

            Internet access is required for this operation.

            Enter "q" to quit without entering an email address.

          EOM

          logger.debug("Attempting to request interactive prompt on TTY")
          prompt = TTY::Prompt.new(track_history: false, active_color: :bold, interrupt: :exit, output: output, input: input)
          answer = prompt.ask("Email Address, or 'q' to quit:")

          unless match = answer =~ /^(q|Q)|(\S+\@\S+)$/ # TODO: validate an email address, LOL
            # TODO: this could be more graceful
            puts "Unrecognized email format '#{answer}'"
            return fetch_license_id_by_email_lookup
          end

          if match[1] == "q" || match[1] == "Q"
            exit_because_user_chose_not_to_enter
          end

          email = match[2]

          # TODO: actually lookup the email using the API
          puts "\nPRETENDING to use an API to find-or-create a LicenseID based on an email...\n"
          license_id = "12345678"

          puts "The email #{email} is associated with \nLicense ID #{license_id}"
          puts "#{BORDER}"
          return license_id
        end

        class PromptTimeout < StandardError; end

      end
    end
  end
end
