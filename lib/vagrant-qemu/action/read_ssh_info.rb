require "log4r"

module VagrantPlugins
  module Qemu
    module Action
      # This action reads the SSH info for the machine and puts it into the
      # `:machine_ssh_info` key in the environment.
      class ReadSSHInfo
        def initialize(app, env)
          @app    = app
          @logger = Log4r::Logger.new("vagrant_qemu::action::read_ssh_info")
        end

        def call(env)
          env[:machine_ssh_info] = read_ssh_info(env[:machine])

          @app.call(env)
        end

        def read_ssh_info(machine)
          return nil if machine.id.nil?

          # Read the DNS info
          output = %x{ #{machine.provider_config.script} ssh-info #{machine.id} }
          if $?.to_i > 0
            raise Errors::QemuError, :message => "Failure: #{env[:machine].provider_config.script} ssh-info #{machine.id}"
          end

          host,port = output.split(/\s+/)[0,2] # TODO check formatting
          return {
            :host => host,
            :port => port
          }
        end
      end
    end
  end
end
