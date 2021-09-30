require "log4r"
require "pp"
require 'vagrant/util/retryable'
require 'vagrant-qemu/util/timer'
require 'json'

module VagrantPlugins
  module Qemu
    module Action
      # This runs the configured instance.
      class RunInstance
        include Vagrant::Util::Retryable

        def initialize(app, env)
          @app    = app
          @logger = Log4r::Logger.new("vagrant_qemu::action::run_instance")
        end

        def disk_file
          @provider_config.disk_file || "#{Dir.home}/.vagrant.d/boxes/arm/0/libvirt/box.img"
        end

        def firmware_location
          "/opt/homebrew/share/qemu"
        end

        def prepare_shell_command(env)
          disk_file_location = self.disk_file
          env[:ui].info("==Disk: #{disk_file_location}")
          %{
          qemu-system-aarch64 \
         -machine virt,accel=hvf,highmem=off \
         -cpu cortex-a72 -smp 2 -m 4G \
         -device intel-hda -device hda-output \
         -device qemu-xhci \
         -device virtio-gpu-gl-pci \
         -device usb-kbd \
         -device virtio-mouse-pci \
         -display cocoa,gl=es \
		     -device e1000,netdev=net0 \
		     -netdev user,id=net0 \
         -drive "if=pflash,format=raw,file=#{firmware_location}/edk2-aarch64-code.fd,readonly=on" \
         -drive "if=pflash,format=raw,file=#{firmware_location}/edk2-arm-vars.fd,discard=on" \
         -drive "if=virtio,format=qcow2,file=#{disk_file_location},discard=on" \
		     -chardev qemu-vdagent,id=spice,name=vdagent,clipboard=on \
		     -device virtio-serial-pci \
		     -device virtserialport,chardev=spice,name=com.redhat.spice.0
          }

        end

        def call(env)
          # Initialize metrics if they haven't been
          env[:metrics] ||= {}

          # Get the configs
          @provider_config = env[:machine].provider_config
          # Launch!
          env[:ui].info(I18n.t("vagrant_qemu.launching_instance"))


          env[:ui].info(JSON.pretty_generate (env[:machine]))
          env[:ui].info(JSON.pretty_generate(@provider_config))


          shell_command = prepare_shell_command(env)
          output = `#{shell_command}`
          if $?.to_i > 0
            raise Errors::QemuError, :message => "Failure with command: #{shell_command}..."
          end
          
          env[:machine].id = output.split(/\s+/)[0]

          # Wait for the instance to be ready first
          env[:metrics]["instance_ready_time"] = Util::Timer.time do
            tries = @provider_config.instance_ready_timeout / 2

            env[:ui].info(I18n.t("vagrant_qemu.waiting_for_ready"))
            begin
              retryable(:on => Qemu::Errors::TimeoutError, :tries => tries) do
                # If we're interrupted don't worry about waiting
                next if env[:interrupted]

                # Wait for the server to be ready
                true
              end
            rescue Qemu::Errors::TimeoutError
              # Delete the instance
              terminate(env)

              # Notify the user
              raise Errors::InstanceReadyTimeout,
                timeout: @provider_config.instance_ready_timeout
            end
          end

          @logger.info("Time to instance ready: #{env[:metrics]["instance_ready_time"]}")

          if !env[:interrupted]
            env[:metrics]["instance_ssh_time"] = Util::Timer.time do
              # Wait for SSH to be ready.
              env[:ui].info(I18n.t("vagrant_qemu.waiting_for_ssh"))
              while true
                # If we're interrupted then just back out
                break if env[:interrupted]
                break if env[:machine].communicate.ready?
                sleep 2
              end
            end

            @logger.info("Time for SSH ready: #{env[:metrics]["instance_ssh_time"]}")

            # Ready and booted!
            env[:ui].info(I18n.t("vagrant_qemu.ready"))
          end

          # Terminate the instance if we were interrupted
          terminate(env) if env[:interrupted]

          @app.call(env)
        end

        def recover(env)
          return if env["vagrant.error"].is_a?(Vagrant::Errors::VagrantError)

          if env[:machine].provider.state.id != :not_created
            # Undo the import
            terminate(env)
          end
        end

        def terminate(env)
          destroy_env = env.dup
          destroy_env.delete(:interrupted)
          destroy_env[:config_validate] = false
          destroy_env[:force_confirm_destroy] = true
          env[:action_runner].run(Action.action_destroy, destroy_env)
        end
      end
    end
  end
end
