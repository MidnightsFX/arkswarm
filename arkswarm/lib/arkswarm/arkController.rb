require 'logger'

module Arkswarm
    module ArkController
        
        def self.set_steam_user(user = nil, pass  = nil)
            username = 'anonymous'
            unless user.nil? && pass.nil?
                username = "#{user} #{pass}" unless user.empty? && passs.empty?
            end
            Arkswarm.set_cfg_value('steamuser', username)
        end

        def self.check_for_server_updates()
            #update_status = `steamcmd +login #{Constants.config['steamuser']} +force_install_dir /server +app_update #{ARKID} +quit`
            update_status = `steamcmd +@ShutdownOnFailedCommand 1 +@NoPromptForPassword 1 +login #{Arkswarm.config['steamuser']} +app_info_update 1 +app_status #{ARKID} +quit`
            LOG.info(update_status)
            return false
        end

    end
end