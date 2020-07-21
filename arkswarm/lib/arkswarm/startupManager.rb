module Arkswarm
  module StartupManager
    # Collect ENV variables arkflag_ & arkarg_
    # Collect configuration defined in [STARTUP_ARGS] ARGS FLAGS
    def self.build_startup_cmd(provided_configs)
      startup_flags = StartupManager.collect_startup_flags(provided_configs)['[startup_flags]']
      startup_args = StartupManager.collect_startup_args(provided_configs)['[startup_args]']
      # Define the active mods
      StartupManager.set_mods(provided_configs['ServerSettings'], startup_args)
      full_start_cmd = StartupManager.build_server_args(startup_args, startup_flags)
      Arkswarm.set_cfg_value(:start_server_cmd, full_start_cmd)
      return full_start_cmd
    end

    # Collects startup FLAGS from the environment and from config files
    def self.collect_startup_flags(provided_configs)
      startup_flags_key = provided_configs.keys.find {|k|  k.downcase == '[startup_flags]'}
      startup_flags_env = ConfigGen.build_cfg_from_envs('arkflag_', '[startup_flags]')
      startup_flags_provided = Util.hash_select(provided_configs, startup_flags_key)
      startup_flags = ConfigLoader.merge_configs(startup_flags_env, startup_flags_provided)
      ConfigGen.remove_blanks!(startup_flags[startup_flags_key]['content'])
      LOG.debug("Collected Startup FLAGS: #{startup_flags}")
      return startup_flags
    end

    # Collects startup ARGS from the environment and from config files
    def self.collect_startup_args(provided_configs)
      startup_args_key = provided_configs.keys.find {|k|  k.downcase == '[startup_args]'}
      startup_args_env = ConfigGen.build_cfg_from_envs('arkarg_', '[startup_args]')
      startup_args_provided = Util.hash_select(provided_configs, startup_args_key)
      startup_args = ConfigLoader.merge_configs(startup_args_env, startup_args_provided)
      LOG.debug("Collected Startup ARGS: #{startup_args}")
      return startup_args
    end

    def self.build_server_args(args, flags)
      startup_flags = []
      startup_args = [Arkswarm.config['map'], 'listen']
      args['content'].each do |arg|
        startup_args << if arg[1].empty?
                          arg[0] # Support for non-key-value entries like 'listen'
                        else
                          arg.join('=')
                        end
      end
      LOG.debug("Startup Args: #{startup_args}")
      flags['content'].each do |flag|
        startup_flags << if flag[1].empty?
                           "-#{flag[0]}"
                         else
                           "-#{flag.join('=')}" # Support key-valued flags
                         end
      end
      LOG.debug("Startup Flags: #{startup_flags}")

      startup_command = "/server/ShooterGame/Binaries/Linux/ShooterGameServer #{startup_args.join('?')} #{startup_flags.join(' ')}"
      LOG.info("Built Startup Command: #{startup_command}")
      return startup_command
    end

    def self.set_mods(provided_configuration, startup_args)
      mods = ''
      mods = Utils.arr_select(startup_args['content'], 'GameModIds')[0][1] if startup_args['keys'].include?('GameModIds')
      if provided_configuration
        if provided_configuration['keys'].include?('ActiveMods')
          LOG.debug('Found ActiveMods config, setting mods')
          mods_source2 = Utils.arr_select(provided_configuration['content'], 'ActiveMods')[0][1]
          mods += mods_source2 unless mods_source2.empty?
        end
      end
      u_mods = mods.split(',').uniq
      LOG.debug("Setting mods to: #{u_mods}")
      Arkswarm.set_cfg_value(:mods, u_mods)
      Arkswarm.set_cfg_value(:mods, []) if u_mods.empty?
    end

    def self.start_server_ensure_running()

    end
  end
end
