module Arkswarm
  module Supervisor

    def self.main_loop(options)
      ArkController.set_steam_user(ENV['steam_user'], ENV['steam_pass'])
      Arkswarm.set_cfg_value(:showcfg, options[:showcfg])
      # Start by generating or regenerating configurations
      # Check for steam user (steam user is required to run DLC maps, Extinction, Aberration_P, ScorchedEarth_P)
      #unless options[:skipgen] # These generations are mostly required for ark to work in this environment
      # ConfigGen.gen_arkmanager_global_conf("/etc/arkmanager", 'arkmanager.cfg', ENV['steam_user'], ENV['steam_pass'])
      # ConfigGen.gen_arkmanager_conf('/etc/arkmanager/instances')
      #end
      if options[:showcfg]
        ConfigGen.readout_file('/etc/arkmanager', 'arkmanager.cfg')
        ConfigGen.readout_file('/etc/arkmanager/instances', 'main.cfg')
      end
      # Check if there is an ARK installation already
      new_server_status = FileManipulator.install_server()

      # Generate Game configurations
      config_location = '/server/ARK/game/ShooterGame/Saved/Config/LinuxServer'
      provided_configs = ConfigLoader.discover_configurations('/config')
      unless options[:skipgen]
        ConfigGen.gen_game_conf(config_location, provided_configs)
        ConfigGen.gen_game_user_conf(config_location, provided_configs)
      end
      if options[:showcfg]
        ConfigGen.readout_file(config_location, 'Game.ini')
        ConfigGen.readout_file(config_location, 'GameUserSettings.ini')
      end

      # Handle Validation CLI option
      FileManipulator.validate_gamefiles(options[:validate])

      # start service
      # check if update is available
      #  - wait until server is idle to update
      Supervisor.run_server(new_server_status)
    end

    # Loops running the server process
    def self.run_server(new_server_status)
      Supervisor.first_run(new_server_status) # this will start up the server, it can take quite a while to update/get started.
      loop do
        # check for updates, restart server if needed, this should block if updates are required
        Supervisor.check_for_updates()
        36.times do # sleep 3600 # sleep one hour
          LOG.info("#{`arkmanager status`}")
          sleep 100
        end
      end
    end

    # Run-once check for an update, if an update is available will update and start back up
    def self.check_for_updates
        update_res = `arkmanager checkupdate`
        update_status = $?.exitstatus
        mod_update_needed = `arkmanager checkmodupdate --revstatus`
        mod_update_status = $?.exitstatus
        if update_status.to_i.zero? && mod_update_status.to_i.zero?
          LOG.info('No Update needed, sleeping.')
          return false
        end
    
        LOG.info('Update Queued, waiting for the server to empty')
        update_status = `arkmanager update --ifempty --validate --saveworld --verbose`
        install_mods = `arkmanager installmods --verbose`
        LOG.info('Checking for mod to install')
        LOG.info(install_mods)
        update_mods = `arkmanager update --update-mods --verbose`
        LOG.info('Checking for mod to update')
        LOG.info(update_mods)
        start_status = `arkmanager start --alwaysrestart --verbose`
        return true
    end

    def self.first_run(new_server_status)
      if new_server_status
        LOG.info("Installing Mods, this can take a while.") 
        modupdate = `arkmanager installmods --verbose`
        LOG.info(modupdate)
      end
      
      # Check status of the server, this should complain about mods which are not installed if we need to install mods
      srv_status = `arkmanager status`
      LOG.info(srv_status.to_s)
      if srv_status.include?('is requested but not installed')
        LOG.info("Mods are missing, starting mod install. This can take a while.")
        srv_status.split("\n").each do |line|
          if line.include?('is requested but not installed') # bit of a hack to install mods which are missing
            cmd = line.split("'")[1]
            LOG.info("Mod install command running: #{cmd}")
            LOG.info(`#{cmd}`)
          end
        end
      end
      
      # Check for game update before starting.
      Supervisor.check_for_updates()
    
      # TODO: setup a backoff for server restart, and integrate discord messaging on failures
      LOG.info("Starting server.")
      start_server = `arkmanager start --alwaysrestart --verbose`
      return start_server
    end
  
  end
end
