module Arkswarm
  module Supervisor
    def self.main_loop(options)
      begin
        # Check for steam user (steam user is required to run DLC maps, Extinction, Aberration_P, ScorchedEarth_P)
        ArkController.set_steam_user(ENV['steam_user'], ENV['steam_pass'])
        Arkswarm.set_cfg_value(:showcfg, options[:showcfg])

        # Ingest Configuration
        provided_configs = ConfigLoader.discover_configurations('/config')

        # Check if there is an ARK installation already
        new_server_status = FileManipulator.install_server()

        # Generate Game configurations
        gameuser_cfg = ConfigGen.gen_game_user_conf(CFG_PATH, provided_configs)
        ConfigGen.gen_game_conf(CFG_PATH, provided_configs) # Also gen game.conf
        ConfigGen.set_ark_globals(gameuser_cfg)

        # Build startup command
        StartupManager.build_startup_cmd(provided_configs)

        # Handle Validation CLI option
        FileManipulator.validate_gamefiles(options[:validate])

        # start service
        # check if update is available
        #  - wait until server is idle to update
        Supervisor.run_server(new_server_status, options[:showstatus])
      rescue StandardError => e
       LOG.error("Encounted Runtime Error: #{e.message}")
       LOG.error("Trace: #{e.backtrace.inspect}")
      end
    end

    # Loops running the server process
    def self.run_server(new_server_status, logstatus = true)
      LOG.debug('Starting server monitoring loop')
      Supervisor.first_run(new_server_status) # this will start up the server, it can take quite a while to update/get started.
      loop do
        # check for updates, restart server if needed, this should block if updates are required
        Supervisor.check_for_updates(logstatus)
        9.times do # sleep 900 # sleep 15 minutes
          LOG.info('Check Server status here.') if logstatus
          sleep 100
          # check about restarting the server if its status is offline
        end
      end
    end

    # Run-once check for an update, if an update is available will update and start back up
    def self.check_for_updates(logstatus = true)
      LOG.debug('Starting Checks for updates.')
      update_status = ArkController.check_for_server_updates()
      missing_mods_status = ArkController.check_for_missing_mods
      mod_updates_needed = ArkController.check_for_mod_updates
      LOG.debug("Updates Needed: ARK-#{update_status['needupdate']} MODS-#{mod_updates_needed} Mods Missing?-#{missing_mods_status}")
      if !update_status['needupdate'] && !mod_updates_needed && !missing_mods_status
        LOG.info('No Update needed.') if logstatus
        return false
      end

      # Connect to RCON and tell the server to save and exit
      # RconExecutor.new()
      # Stop the server
      if update_status['needupdate']
        LOG.info('ARK needs an update, updating.')
        ArkController.update_install_ark
      end
      if mod_updates_needed || missing_mods_status
        LOG.info('Mods need an update')
        ArkController.check_mods_and_update(true)
      end
      LOG.info('Starting server back up.')
      LOG.debug("Server thread starting: #{ArkController.start_arkserver_thread()}")
      return true
    end

    def self.first_run(new_server_status)
      LOG.info('Starting server firstrun check')
      if new_server_status
        LOG.info('New Server, installing ARK and Mods.')
        ArkController.update_install_ark(true) # update/install & validate ARK
        ArkController.check_mods_and_update(true) # update & validate Mods
      end
      # LOG.info(srv_status.to_s)
      # Implement server status check
      ArkController.check_mods_and_update(true) if Util.true?(ArkController.check_for_missing_mods)
      # Check for game update before starting.
      Supervisor.check_for_updates()
      # TODO: setup a backoff for server restart, and integrate discord messaging on failures
      LOG.info('Starting server.')
      start_server = ArkController.start_arkserver_thread()
      sleep 500
      # TODO: Loop until the server is running
      Arkswarm.connect_to_rcon()
      return start_server
    end
  end
end
