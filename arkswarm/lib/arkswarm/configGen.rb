module Arkswarm
  module ConfigGen

    def self.set_ark_globals(gameuser_cfg)
      # These only comes from ENV values
      server_map = ENV['serverMap'].nil? ? 'TheIsland' : ENV['serverMap']
      server_map = 'TheIsland' if server_map.empty? # ensure its not just set to nothing
      session_name = ENV['sessionName'].nil? ? 'Arkswarm' : ENV['sessionName']
      session_name = 'Arkswarm' if session_name.empty? # ensure its not just set to nothing
      srv_pass = Util.arr_select(gameuser_cfg['ServerSettings'], 'ServerPassword')

      # Early add mods
      mods = ENV['GameModIds'].split(',') unless ENV['GameModIds'].nil?
      mods = ENV['mods'].split(',') unless ENV['mods'].nil? && mods.nil?
      Arkswarm.set_cfg_value(:mods, mods) unless mods.nil?

      user_srv_pass = if srv_pass.empty?
                        ''
                      else
                        srv_pass[1]
                      end
      adminpass = ENV['adminpass'].nil? ? 'lazyadmin' : ENV['adminpass']
      adminpass = 'lazyadmin' if adminpass.empty? # ensure its not just set to nothing
      LOG.debug("Storing globals: map-#{server_map}, sessionName-#{session_name}, serverpass-#{user_srv_pass}, adminpass-#{adminpass}, mods-#{mods}")
      Arkswarm.set_cfg_value('map', server_map)
      Arkswarm.set_cfg_value('sessionname', session_name)
      Arkswarm.set_cfg_value('serverpass', user_srv_pass)
      Arkswarm.set_cfg_value('adminpass', adminpass)
    end

    def self.gen_game_conf(ark_cfg_dir, provided_configuration = nil)
      cfgname = 'Game.ini'
      FileManipulator.ensure_file(ark_cfg_dir, cfgname)
      env_cfg = ConfigGen.build_cfg_from_envs('arkgame_', '[/script/shootergame.shootergamemode]')
      contents = ConfigLoader.parse_ini_file("#{ark_cfg_dir}/#{cfgname}")
      game_cfg = ConfigGen.merge_config_by_type(:game, contents, provided_configuration) unless provided_configuration.nil?
      LOG.debug("Partial Configuration #{game_cfg}") if Arkswarm.config[:verbose]
      final_game_cfg = ConfigGen.merge_config_by_type(:game, game_cfg, env_cfg)
      ConfigGen.gen_addvalues_read_write_cfg(ark_cfg_dir, cfgname, final_game_cfg)
      return final_game_cfg
    end

    # This will take all ENV variables with gameuser_ and use them to generate a configuration
    def self.gen_game_user_conf(ark_cfg_dir, provided_configuration = nil)
      cfgname = 'GameUserSettings.ini'
      FileManipulator.ensure_file(ark_cfg_dir, cfgname)
      env_cfg = ConfigGen.build_cfg_from_envs('gameuser_', '[serversettings]')
      contents = ConfigLoader.parse_ini_file("#{ark_cfg_dir}/#{cfgname}")
      game_user_cfg = ConfigGen.merge_config_by_type(:gameini, contents, provided_configuration) unless provided_configuration.nil?
      final_gameuser_cfg = ConfigGen.merge_config_by_type(:game, game_user_cfg, env_cfg)
      ConfigGen.gen_addvalues_read_write_cfg(ark_cfg_dir, cfgname, final_gameuser_cfg)
      return final_gameuser_cfg
    end

    # merges the total jumble of configs into the correct places
    def self.merge_config_by_type(type, primary_config, provided_configuration)
      merged_configuration = {}
      shootergame_key = provided_configuration.keys.find {|k| k.downcase == '[/script/shootergame.shootergamemode]'}
      prime_shootergame_key = primary_config.keys.find {|k| k.downcase == '[/script/shootergame.shootergamemode]'}
      if type == :game
        # merge only '[/script/shootergame.shootergamemode]', does nothing if that doesnt exist
        LOG.debug("Checking for shootergame key: #{provided_configuration.keys} found? #{shootergame_key}")
        if !shootergame_key.nil?
          cased_provided_cfg = { '[/Script/ShooterGame.ShooterGameMode]' => provided_configuration[shootergame_key] } # Ark cares about the casing so we need to also...
          shooter_cfg = { '[/Script/ShooterGame.ShooterGameMode]' => primary_config[prime_shootergame_key] } if primary_config[prime_shootergame_key]
          shooter_cfg = { '[/Script/ShooterGame.ShooterGameMode]' => provided_configuration[shootergame_key] } if primary_config[prime_shootergame_key] && shooter_cfg.nil?
          shooter_cfg = { '[/Script/ShooterGame.ShooterGameMode]' => { 'content' => [], 'keys' => [] } } if shooter_cfg.nil?
          LOG.debug("Providing: #{shooter_cfg} & #{cased_provided_cfg}") if Arkswarm.config[:verbose]
          merged_configuration = ConfigLoader.merge_configs(shooter_cfg, cased_provided_cfg)
        else
          LOG.debug('Shootergame key not found, skipping merge.')
        end
      else
        # Merge everything but "[/script/shootergame.shootergamemode]" which is for game and "[startup_*]" which is for startup arguments
        startup_args_key = provided_configuration.keys.find {|k| k.downcase == '[startup_args]'}
        startup_flags_key = provided_configuration.keys.find {|k| k.downcase == '[startup_flags]'}
        cfg = Util.hash_remove_keys(provided_configuration, shootergame_key, startup_args_key, startup_flags_key)
        merged_configuration = ConfigLoader.merge_configs(primary_config, cfg)
      end
      if Arkswarm.config[:verbose]
        LOG.debug('Returning merged configuration.')
        LOG.debug(merged_configuration.to_s)
      end
      return merged_configuration
    end

    # Takes a specified partial key and searches ENV variables for those, then builds a sectioned hash based on them
    def self.build_cfg_from_envs(env_key_partial, section_header = 'ungrouped')
      partial_key = env_key_partial.downcase
      env_hash = {}
      env_hash[section_header] = { 'content' => [], 'keys' => [] }
      ENV.keys.each do |key|
        next unless key.include?(partial_key)

        line_contents = "#{key.gsub(partial_key, '')}=#{ENV[key]}".split('=')
        line_contents << '' if line_contents.length == 1
        env_hash[section_header]['content'] << line_contents
        env_hash[section_header]['keys'] << key.gsub(partial_key).to_s
      end
      LOG.debug("Built ENV Hash: #{env_hash}")
      return env_hash
    end

    # Adds required values to the contents, generates a new config file and writes it out, and then reads it to the logger
    def self.gen_addvalues_read_write_cfg(cfg_dir, cfgname, contents)
      ConfigLoader.generate_config_file(contents, "#{cfg_dir}/#{cfgname}")
      ConfigGen.readout_file(cfg_dir, cfgname)
      return contents # Final contents of file
    end

    # Logs the configuration file contents
    def self.readout_file(file_location, filename)
      return false unless File.file?("#{file_location}/#{filename}")

      LOG.info("Generated #{filename} Configuration File:")
      LOG.info("#{file_location}/#{filename}")
      if Arkswarm.config[:showcfg]
        LOG.info('----------------- Config Start -----------------')
        LOG.info("\n#{File.readlines("#{file_location}/#{filename}").join}")
        LOG.info('----------------- Config End -------------------')
      end
    end

    # For things that cant handle spaces, like startup args
    def self.remove_blanks!(content_array)
      content_array.reject! do |entry|
        if entry.nil?
          true
        elsif entry[0].nil?
          true
        else
          entry[0].empty?
        end
      end
    end
  end
end
