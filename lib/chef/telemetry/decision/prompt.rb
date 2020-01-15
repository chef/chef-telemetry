# Use same support libraries as license-acceptance
require "tty-prompt"
require "pastel"
require "timeout"
require "chef-config/windows"

class Chef
  class Telemetry
    class Decision
      # Represents a decision made by interactively prompting the user
      class Prompt

        attr_reader :logger, :output, :input

        PASTEL = Pastel.new
        BORDER = "+---------------------------------------------+".freeze
        YES = PASTEL.green.bold("y")
        CHECK = PASTEL.green(ChefConfig.windows? ? "√" : "✔")

        def initialize(cfg)
          @logger = cfg[:logger]
          @output = cfg[:output]
          @input = cfg[:input] || STDIN
        end

        def prompt(dir, persistor)
          logger.debug "Prompting for opt-in/out..."

          optin_question = "Enable usage data collection (#{YES}/n)?"

          output.puts <<~EOM
            #{BORDER}
                        Chef Telemetry Opt-In
            Optionally, you may choose to participate in
            the Chef Telemetry program, which helps improve
            Chef products by collecting data. View the
            Privacy Policy at:
            https://www.chef.io/privacy-policy/

            #{optin_question}
          EOM

          ask(dir, persistor)
        end

        private

        def ask(dir, persistor)
          logger.debug("Attempting to request interactive prompt on TTY")
          prompt = TTY::Prompt.new(track_history: false, active_color: :bold, interrupt: :exit, output: output, input: input)
          answer = false
          timeout = ENV["CI_TELEMETRY_PROMPT_TIMEOUT"].nil? ? 60 : ENV["CI_TELEMETRY_PROMPT_TIMEOUT"].to_i
          handle_timeout = ->() {
            prompt.unsubscribe(prompt.reader)
            output.puts "\nPrompt timed out. Opting out of telemetry\nfor this run."
            # Do not opt-in on timeout
            return false
          }

          if ChefConfig.windows?
            # On windows, Timeout hangs on STDIN. TTY::Prompt's keypress is safe, but we
            # can't distinguish a "timeout default" from a "they just pressed enter default"
            # So, assume all defaults are opt-out.
            answer = prompt.keypress("y/n?", default: "t", timeout: timeout)
            return handle_timeout.call if answer == "t"
            answer = answer == "y"
          else
            begin
              Timeout.timeout(timeout, PromptTimeout) do
                answer = prompt.yes?(">")
              end
            rescue PromptTimeout
              return handle_timeout.call
            end
          end

          logger.debug "Saw answer #{answer}"

          output.puts
          inout = answer ? "opt-in" : "opt-out"
          enabled = answer ? "Enabled" : "Disabled"
          output.puts "Persisting telemetry #{inout} decision..."

          errs = persistor.persist(answer, dir)

          if errs.empty?
            output.puts "#{CHECK} #{enabled} telemetry\n\n"
          else
            output.puts <<~EOM
              #{CHECK} #{enabled} telemetry
              Could not persist decision:\n\t* #{errs.map(&:message).join("\n\t* ")}
            EOM
          end
          answer
        end

        class PromptTimeout < StandardError; end

      end
    end
  end
end
