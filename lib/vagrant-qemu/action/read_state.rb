require "log4r"

module VagrantPlugins
  module Qemu
    module Action
      # This action reads the state of the machine and puts it in the
      # `:machine_state_id` key in the environment.
      class ReadState
        def initialize(app, env)
          @app    = app
          @logger = Log4r::Logger.new("vagrant_qemu::action::read_state")
        end

        def call(env)
          env[:machine_state_id] = read_state(env[:machine])

          @app.call(env)
        end

        def read_state(machine)
          return :not_created if machine.id.nil?

          # Return the state
          output = %x{ #{machine.provider_config.script} read-state #{machine.id} }
          if $?.to_i > 0
            raise Errors::QemuError, :message => "Failure: #{env[:machine].provider_config.script} read-state #{machine.id}"
          end
          output.strip
        end
      end
    end
  end
end
