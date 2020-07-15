require 'rcon'

module Arkswarm
    class RconExecutor
        @client = nil

        def self.initialize(host: host, port: port, password: password)
            @client = Rcon::Client.new(host: host, port: port, password: password)
            @client.authenticate!
        end

        def self.execute(cmd)
            return client.execute("#{cmd}")
        end
    end
end


