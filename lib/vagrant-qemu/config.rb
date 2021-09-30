require "vagrant"

module VagrantPlugins
  module Qemu
    class Config < Vagrant.plugin("2", :config)
      # The disk_file to use.
      #
      # @return [String]
      attr_accessor :disk_file

      # The firmware to use.
      #
      # @return [String]
      attr_accessor :firmware_location

      # The timeout to wait for an instance to become ready.
      #
      # @return [Fixnum]
      attr_accessor :instance_ready_timeout

      # The user data string
      #
      # @return [String]
      attr_accessor :user_data

      # The qemu script implementing some tech
      # 
      # @return [String]
      attr_accessor :script

      # The qemu script run-instance args
      # 
      # @return [String]
      attr_accessor :run_args

      def initialize
        @disk_file              = UNSET_VALUE
        @firmware_location      = UNSET_VALUE
        @instance_ready_timeout = UNSET_VALUE
        @user_data              = UNSET_VALUE
        @script                 = UNSET_VALUE
        @run_args               = UNSET_VALUE

        # Internal state (prefix with __ so they aren't automatically
        # merged)
        @__finalized = false
      end

      #-------------------------------------------------------------------
      # Internal methods.
      #-------------------------------------------------------------------

      def merge(other)
        super.tap do |result|
        end
      end

      def finalize!
        # disk_filemust be nil, since we can't default that
        @disk_file= nil if @disk_file== UNSET_VALUE

        @firmware_location= nil if @firmware_location == UNSET_VALUE

        # Set the default timeout for waiting for an instance to be ready
        @instance_ready_timeout = 120 if @instance_ready_timeout == UNSET_VALUE

        # User Data is nil by default
        @user_data = nil if @user_data == UNSET_VALUE

        # No default qemu script
        @script = nil if @script == UNSET_VALUE

        # No rub args by default
        @run_args = [] if @run_args == UNSET_VALUE

        # Mark that we finalized
        @__finalized = true
      end

      def validate(machine)
        { "Qemu Provider" => [ ] } 
      end

    end
  end
end
