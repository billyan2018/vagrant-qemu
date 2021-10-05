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


        def prepare_shell_command(env)
          qemu_command = @provider_config.qemu_command || "qemu-system-aarch64"

          disk_file_location = @provider_config.disk_file || "#{env[:machine].box.directory}/box.img"
          env[:ui].info("==Disk: #{disk_file_location}")
          command = %{
          #{qemu_command} \
         -machine #{@provider_config.machine || "virt,accel=hvf,highmem=off"} \
         -cpu #{@provider_config.cpu || "host"} \
         -smp #{@provider_config.smp || "2"} \
         -m #{@provider_config.memory || "4G"} \
         -display #{@provider_config.display || "cocoa,gl=es"} \
         -device intel-hda -device hda-output \
         -device qemu-xhci \
         -device #{@provider_config.gpu ||"virtio-gpu-gl-pci"} \
         -device usb-kbd \
         -device #{@provider_config.mouse ||"usb-tablet"} \
		     -device e1000,netdev=net0 \
		     -netdev user,id=net0 \
         -drive "if=virtio,format=qcow2,file=#{disk_file_location},discard=on" \
		     -chardev qemu-vdagent,id=spice,name=vdagent,clipboard=on \
		     -device virtio-serial-pci \
		     -device virtserialport,chardev=spice,name=com.redhat.spice.0 }
          if @provider_config.firmware_location != nil || !(qemu_command.include?("x86_64"))
            firmware_path = @provider_config.firmware_location || "/opt/homebrew/share/qemu/edk2-aarch64-code.fd"
            env[:ui].info("==Firmware: #{firmware_path}")
            command = "#{command} -drive \"if=pflash,format=raw,file=#{firmware_path},readonly=on\""
          end
          if @provider_config.additional_line != nil
            command = "#{command} #{@provider_config.additional_line}"
          end
          command
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
          env[:ui].info("command:\n#{shell_command}")
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
