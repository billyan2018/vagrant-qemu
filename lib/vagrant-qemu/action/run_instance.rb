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

        def disk_file(env)
          @provider_config.disk_file || "#{env[:machine].box.directory}/box.img"
        end

        def firmware_location
          @provider_config.firmware_location || "/opt/homebrew/share/qemu"
        end

        def prepare_shell_command(env)
          qemu_command = @provider_config.qemu_command || "qemu-system-aarch64"
          machine = @provider_config.machine || "virt,accel=hvf,highmem=off"
          cpu = @provider_config.cpu || "host"
          memory = @provider_config.memory || "4G"
          smp = @provider_config.smp || "2"
          display = @provider_config.display || "cocoa,gl=es"

          firmware_path = firmware_location
          env[:ui].info("==Firmware: #{firmware_path}")
          disk_file_location = self.disk_file(env)
          env[:ui].info("==Disk: #{disk_file_location}")
          %{
          #{qemu_command} \
         -machine #{machine} \
         -cpu #{cpu} \
         -smp #{smp} \
         -m #{memory} \
         -display #{display} \
         -device intel-hda -device hda-output \
         -device qemu-xhci \
         -device virtio-gpu-gl-pci \
         -device usb-kbd \
         -device virtio-mouse-pci \
		     -device e1000,netdev=net0 \
		     -netdev user,id=net0 \
         -drive "if=pflash,format=raw,file=#{firmware_path}/edk2-aarch64-code.fd,readonly=on" \
         -drive "if=pflash,format=raw,file=#{firmware_path}/edk2-arm-vars.fd,discard=on" \
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
          @logger.info("vagrant_qemu.launching_instance")

          @logger.debug("aaaaaaa")
          @logger.debug(env[:machine].to_yaml)
          @logger.debug("-----------")
          @logger.debug(@provider_config.to_yaml())


          shell_command = prepare_shell_command(env)
          @logger.info("command:#{shell_command}")
          env[:machine].id = spawn(shell_command)
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
