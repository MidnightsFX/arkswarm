module Arkswarm
  module ConfigGen

    # This modifies the global config
    # def self.gen_arkmanager_global_conf(ark_mgr_dir = "/etc/arkmanager", cfgname = 'arkmanager.cfg', user = nil, pass = nil)
    #   user = 'anonymous' if user.nil? # This is defined here because an empty envar can be passed
    #   required_lines = []
    #   if user == 'anonymous'
    #     required_lines << "steamlogin=anonymous"
    #   else
    #     required_lines << "steamlogin=\"#{user} #{pass}\""
    #   end
    #   contents = ConfigLoader.parse_ini_file("#{ark_mgr_dir}/#{cfgname}")
    #   ConfigGen.gen_addvalues_read_write_cfg(ark_mgr_dir, cfgname, contents, required_lines)
    #   
    # end
    
    # This will take all ENV variables with game_ and use them to generate a configuration
    # This is for the arkmanager instance configuration (IE this containers ARK, mostly deals with startup args)
    # def self.gen_arkmanager_conf(ark_mgr_dir, cfgname = 'main.cfg')
    #   FileManipulator.ensure_file(ark_mgr_dir, cfgname)
    #   required_lines = []
    #   required_lines << "arkserverroot=/server/ARK/game"
    #   ENV.keys.each do |key|
    #     next unless key.include?('arkopt_') || key.include?('ark_') || key.include?('arkflag_') || ARK_INSTANCE_VARS.include?(key)
    #     # key.gsub('arkopt_', '').gsub('ark_', '').gsub('arkflag_', '')
    #     required_lines << "#{key}=\"#{ENV[key]}\""
    #   end
    #   contents = ConfigLoader.parse_ini_file("#{ark_mgr_dir}/#{cfgname}")
    #   ConfigGen.gen_addvalues_read_write_cfg(ark_mgr_dir, cfgname, contents, required_lines)
    # end

    def self.ark_startup_args()
      map = ENV['map'].nil? ? 'TheIsland' : ENV['map']
      session = ENV['session'].nil? ? 'Arkswarm' : ENV['session']
      serverpass = ENV['serverpass'].nil? ? 'test1234' : ENV['serverpass']
      adminpass = ENV['adminpass'].nil? ? 'lazyadmin' : ENV['adminpass']
      
      Constants.set_cfg_value('map', map)
      Constants.set_cfg_value('session', session)
      Constants.set_cfg_value('session', serverpass)
      Constants.set_cfg_value('adminpass', adminpass)
    end

    def self.gen_game_conf(ark_cfg_dir, provided_configuration = nil)
      cfgname = 'Game.ini'
      FileManipulator.ensure_file(ark_cfg_dir, cfgname)
      required_lines = []
      ENV.keys.each do |key|
        next unless key.include?('arkgame_')
        required_lines << "#{key.gsub('arkgame_', '')}=#{ENV[key]}"
      end
      contents = ConfigLoader.parse_ini_file("#{ark_cfg_dir}/#{cfgname}")
      game_cfg = ConfigGen.merge_config_by_type(:game, contents, provided_configuration) unless provided_configuration.nil?
      return ConfigGen.gen_addvalues_read_write_cfg(ark_cfg_dir, cfgname, game_cfg, required_lines)
    end

    # This will take all ENV variables with gameuser_ and use them to generate a configuration
    def self.gen_game_user_conf(ark_cfg_dir, provided_configuration = nil)
      cfgname = "GameUserSettings.ini"
      FileManipulator.ensure_file(ark_cfg_dir, cfgname)
      required_lines = []
      ENV.keys.each do |key|
        next unless key.include?('gameuser_')
        required_lines << "#{key.gsub('gameuser_', '')}=#{ENV[key]}"
      end
      contents = ConfigLoader.parse_ini_file("#{ark_cfg_dir}/#{cfgname}")
      game_user_cfg = ConfigGen.merge_config_by_type(:gameini, contents, provided_configuration) unless provided_configuration.nil?
      return ConfigGen.gen_addvalues_read_write_cfg(ark_cfg_dir, cfgname, game_user_cfg, required_lines)
    end

    # merges the total jumble of configs into the correct places
    def self.merge_config_by_type(type, primary_config, provided_configuration)
      merged_configuration = {}
      shootergame_key = provided_configuration.keys.find {|k|  k.downcase == '[/script/shootergame.shootergamemode]'}
      if type == :game
        # merge only '[/script/shootergame.shootergamemode]', does nothing if that doesnt exist
        LOG.debug("Checking for shootergame key: #{provided_configuration.keys} found? #{shootergame_key}")
        unless shootergame_key.nil?
          cased_provided_cfg = { '[/Script/ShooterGame.ShooterGameMode]' => provided_configuration[shootergame_key] } # Ark cares about the casing so we need to also...
          shooter_cfg = if primary_config[shootergame_key] 
                          { '[/Script/ShooterGame.ShooterGameMode]' => primary_config[shootergame_key] }
                        else # primary config might not have this section, in which case we need to provide an empty one
                          { '[/Script/ShooterGame.ShooterGameMode]' => { 'content' => [], 'keys' => []} }
                        end
          LOG.debug("Providing: #{shooter_cfg} & #{cased_provided_cfg}")
          merged_configuration = ConfigLoader.merge_configs(shooter_cfg, cased_provided_cfg)
        end
      else
        # Merge everything but "[/script/shootergame.shootergamemode]" which is for game
        merged_configuration = ConfigLoader.merge_configs(primary_config, provided_configuration.tap {|hs| hs.delete(shootergame_key)})
      end
      LOG.debug("Returning merged configuration.")
      return merged_configuration
    end

    # Adds required values to the contents, generates a new config file and writes it out, and then reads it to the logger
    def self.gen_addvalues_read_write_cfg(cfg_dir, cfgname, contents, required_lines = nil)
      unless required_lines.empty?
        required_lines.each do |req_line|
          kv = req_line.split("=")
          ConfigLoader.update_cfg_value(contents, kv[0], kv[1])
        end
      end
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
        LOG.info("\n#{File.readlines("#{file_location}/#{filename}").join.to_s}")
        LOG.info('----------------- Config End -------------------')
      end
    end

  end
end
