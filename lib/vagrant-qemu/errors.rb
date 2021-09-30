require "vagrant"

module VagrantPlugins
  module Qemu
    module Errors
      class VagrantQemuError < Vagrant::Errors::VagrantError
        error_namespace("vagrant_qemu.errors")
      end

      class QemuError < VagrantQemuError
        error_key(:qemu_error)
      end

      class TimeoutError < VagrantQemuError
        error_key(:instance_ready_timeout)
      end

      class ComputeError < VagrantQemuError
        error_key(:instance_ready_timeout)
      end

      class InstanceReadyTimeout < VagrantQemuError
        error_key(:instance_ready_timeout)
      end
    end
  end
end
