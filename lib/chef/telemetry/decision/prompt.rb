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
        CHECK = PASTEL.green(ChefConfig.windows? ? "√" : "✔")
        X_MARK = PASTEL.red(ChefConfig.windows? ? "x" : "×")
        CIRCLE = PASTEL.green(ChefConfig.windows? ? "O" : "◯")

        def initialize(cfg)
          @logger = cfg[:logger]
          @output = cfg[:output]
          @input = cfg[:input] || STDIN
        end

        def prompt(dir, persistor)
          logger.debug "Prompting for opt-in/out..."

          output.puts <<~EOM
            #{BORDER}
            Share Data with Chef
            Chef would like to collect anonymized usage and
            diagnostic data to help improve your experience.

            Privacy Policy: https://www.chef.io/privacy-policy/

            Allow Chef to collect anonymized usage and
            diagnostic data (yes/no)?
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
            output.puts "\nPrompt timed out. Opting out of usage data\nfor this run."
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
          output.puts "Saving data sharing setting..."

          errs = persistor.persist(answer, dir)

          mark = answer ? CHECK : CIRCLE

          if errs.empty?
            output.puts "#{mark} Data sharing setting saved\n\n"
          else
            output.puts <<~EOM
              #{mark} Data sharing setting saved
              #{X_MARK} Could not save decision:\n\t* #{errs.map(&:message).join("\n\t* ")}
            EOM
          end
          answer
        end

        class PromptTimeout < StandardError; end

      end
    end
  end
end
