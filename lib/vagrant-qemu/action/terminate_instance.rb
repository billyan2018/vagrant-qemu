require "log4r"

module VagrantPlugins
  module Qemu
    module Action
      # This terminates the running instance.
      class TerminateInstance
        def initialize(app, env)
          @app    = app
          @logger = Log4r::Logger.new("vagrant_qemu::action::terminate_instance")
        end

        def call(env)
          # Destroy the server and remove the tracking ID
          pid = env[:machine].id
          env[:ui].info(I18n.t("vagrant_qemu.terminating"))
          output = %x{ kill -9 #{pid} }
          if $?.to_i > 0
            raise Errors::QemuError, :message => "Failure: terminate-instance #{env[:machine].id}"
          end

          puts output

          env[:machine].id = nil

          @app.call(env)
        end
      end
    end
  end
end
