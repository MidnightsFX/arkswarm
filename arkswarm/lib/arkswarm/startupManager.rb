module Arkswarm
    module StartupManager

        # Collect ENV variables arkflag_ & arkarg_
        # Collect configuration defined in [STARTUP_ARGS] ARGS FLAGS
        def self.build_startup_cmd(provided_configs)
            startup_args_key = provided_configs.keys.find {|k|  k.downcase == '[startup_args]'}
            startup_flags_key = provided_configs.keys.find {|k|  k.downcase == '[startup_flags]'}

            startup_args_env = ConfigGen.build_cfg_from_envs('arkarg_', '[startup_args]')
            startup_flags_env = ConfigGen.build_cfg_from_envs('arkflag_', '[startup_flags]')

            startup_args = ConfigGen.merge_configs(startup_args_env, provided_configs[startup_args_key])
            startup_flags = ConfigGen.merge_configs(startup_flags_env, provided_configs[startup_flags_key])

            return StartupManager.build_server_args(startup_args, startup_flags)
        end

        def self.build_server_args(args, flags)
            startup_flags = []
            startup_args = ["#{cfg['map']}", 'listen']
            args['content'].each do |arg|
                if arg[1].empty?
                    startup_args << arg[0] # Support for non-key-value entries like 'listen'
                else
                    startup_args << arg.join('=')
                end
            end
            LOG.debug("Startup Args: #{startup_args}")
            flags['content'].each do |flag|
                if flag[1].empty?
                    startup_flags << "-#{flag[0]}"
                else
                    startup_flags << "-#{flag.join('=')}" # Support key-valued flags
                end
            end
            LOG.debug("Startup Flags: #{startup_flags}")

            startup_command = "/server/ShooterGame/Binaries/Linux/ShooterGameServer #{startup_args.join('?')} #{startup_flags.join(" ")}"
            LOG.info("Build Startup Command: #{startup_command}")
            return startup_command
        end 
    end
end
