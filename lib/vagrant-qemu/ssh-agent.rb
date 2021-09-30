# fool vagrant into using ssh-agent keys instead of a fixed key on file
module Vagrant
  module Util
    class Platform
      def self.solaris?
        true
      end
    end
  end
end

require "net/ssh"

module Net::SSH
  class << self
    alias_method :old_start, :start
    
    def start(host, username, opts)
      opts[:keys_only] = false
      self.old_start(host, username, opts)
    end
  end
end 
