require "log4r"
require "json"
module VagrantPlugins
  module Qemu
    module Action
      # This action reads the state of the machine and puts it in the
      # `:machine_state_id` key in the environment.
      class ReadState
        def initialize(app, env)
          @app    = app
          @logger = Log4r::Logger.new("vagrant_qemu::action::read_state")
          @env
        end

        def call(env)
          env[:machine_state_id] = read_state(env)

          @app.call(env)
        end

        def read_state(env)
          machine = env[:machine]
          pid = machine.id
          env[:ui].info("======= #{pid}")
          if pid.nil? || !(pid.is_a? Numeric)
            :not_created
          else
            begin
              Process.getpgid( pid )
              :running
            rescue Errno::ESRCH
              :not_created
            end
          end
        end
      end
    end
  end
end
