require "vagrant-qemu/util/timer"

module VagrantPlugins
  module Qemu
    module Action
      # This is the same as the builtin provision except it times the
      # provisioner runs.
      class TimedProvision < Vagrant::Action::Builtin::Provision
        def run_provisioner(env)
          timer = Util::Timer.time do
            super
          end

          env[:metrics] ||= {}
          env[:metrics]["provisioner_times"] ||= []
          # env[:metrics]["provisioner_times"] << [name, timer]
        end
      end
    end
  end
end
