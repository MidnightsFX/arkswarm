require "arkswarm/configGen"
require "arkswarm/configLoader"
require "arkswarm/fileManipulator"
require "arkswarm/arkController"
require "arkswarm/supervisor"
require "arkswarm/constants"
require "arkswarm/utils"

module Arkswarm
    # Handle being told to kill the container
    Signal.trap("TERM") {
        Arkswarm.shutdown_hook
    }

    # Handle user requested exit
    Signal.trap("SIGINT") {
        Arkswarm.shutdown_hook
    }

    def self.shutdown_hook
        puts 'Recieved shutdown, starting shutdown.'
        `arkmanager stop --saveworld`
        puts 'Saved and shutdown, exiting.'
        exit
    end

end
