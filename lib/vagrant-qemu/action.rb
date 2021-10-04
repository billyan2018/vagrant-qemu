require "pathname"

require "vagrant/action/builder"

module VagrantPlugins
  module Qemu
    module Action
      @logger = Log4r::Logger.new("vagrant_qemu::action::base")
      # Include the built-in modules so we can use them as top-level things.
      include Vagrant::Action::Builtin

      # This action is called to terminate the remote machine.
      def self.action_destroy
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use TerminateInstance
        end
      end

      # This action is called when `vagrant provision` is called.
      def self.action_provision
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use Call, IsCreated do |env, b2|
            if !env[:result]
              b2.use MessageNotCreated
              next
            end

            b2.use Provision
          end
        end
      end



      # This action is called to read the state of the machine. The
      # resulting state is expected to be put into the `:machine_state_id`
      # key.
      def self.action_read_state
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use ReadState
        end
      end



      # This action is called to bring the box up from nothing.
      def self.action_up
        @logger.info("action_up")
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use HandleBox
          b.use BoxCheckOutdated
          #b.use Call, IsCreated do |env, b2|
          # Handle box_url downloading early so that if the Vagrantfile
          # references any files in the box or something it all just
          # works fine.
          #b.use Call, IsState, :not_created do |env1, b1|
          #  @logger.info(env1[:result])
          #  if env1[:result]
          #    b1.use HandleBox
          #  end
          #end

          b.use ConfigValidate
          b.use Call, IsCreated do |env, b2|
            if env[:result]
              b2.use MessageAlreadyCreated
              next
            end

            b2.use TimedProvision
            b2.use RunInstance
          end
        end
      end

      # The autoload farm
      action_root = Pathname.new(File.expand_path("../action", __FILE__))
      autoload :IsCreated, action_root.join("is_created")
      autoload :MessageAlreadyCreated, action_root.join("message_already_created")
      autoload :MessageNotCreated, action_root.join("message_not_created")
      autoload :ReadState, action_root.join("read_state")
      autoload :RunInstance, action_root.join("run_instance")
      autoload :TimedProvision, action_root.join("timed_provision")
      autoload :TerminateInstance, action_root.join("terminate_instance")
    end
  end
end
