require 'rcon'

module Arkswarm
    class RconInstance
        @client = nil

        def self.initialize(host: host, port: port, password: password)
            @client = Rcon::Client.new(host: host, port: port, password: password)
            @client.authenticate!
        end

        def self.execute(cmd)
            return client.execute("#{cmd}")
        end
    end

    # Instanceless master executor? since we are just managing one server per container
    # module RconExecutor
    #     
    # end
end


