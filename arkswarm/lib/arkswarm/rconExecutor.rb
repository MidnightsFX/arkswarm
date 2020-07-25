require 'rcon'

module Arkswarm
  # Build an instance of the RCON Client, used to issue admin commands to ARK
  class RconInstance
    @client = nil

    def initialize(host = 'localhost', port, password)
      @client = Rcon::Client.new(host: host, port: port, password: password)
      @client.authenticate!
    end

    def execute(cmd)
      return @client.execute(cmd.to_s)
    end
  end

  def self.connect_to_rcon()
    rcon_connection = RconInstance.new('localhost', Arkswarm.config[:rcon_port], Arkswarm.config[:admin_pass])
    Arkswarm.config[:rcon_client] = rcon_connection
  end

  # Instanceless master executor? since we are just managing one server per container
  # module RconExecutor
  #
  # end
end
