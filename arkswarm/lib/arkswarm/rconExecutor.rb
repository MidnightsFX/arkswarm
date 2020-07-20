require 'rcon'

module Arkswarm
  # Build an instance of the RCON Client, used to issue admin commands to ARK
  class RconInstance
    @client = nil

    def self.initialize(host: 'localhost', port:, password:)
      @client = Rcon::Client.new(host: host, port: port, password: password)
      @client.authenticate!
    end

    def self.execute(cmd)
      return client.execute(cmd.to_s)
    end
  end

  def self.connect_to_rcon()
    rcon_connection = RconInstance.new(host: 'localhost', port: Arkswarm.config[:rcon_port], pass: Arkswarm.config[:admin_pass])
    Arkswarm.config[:rcon_client] = rcon_connection
  end

  # Instanceless master executor? since we are just managing one server per container
  # module RconExecutor
  #
  # end
end
