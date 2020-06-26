
module Arkswarm
    module FileManipulator

        # walks the filepath and if there is no file/folder there it will generate them, does nothing if they exist
        def self.ensure_file(location, filename = nil)
            ug_info = File.stat('/home/steam/steamcmd/steamcmd.sh')
            folder_location = '/'
            location.split('/').each do |segment|
                next if segment == '' # skip start or end slashes
                folder_location = folder_location + segment + "/"
                next if Dir.exist?(folder_location) # do nothing if this folder exists
                Dir.mkdir(folder_location)
                File.chown(ug_info.uid, ug_info.gid, folder_location)
            end
            if filename
                # If the file does not exist make a blank one. This is primarily for first gen, when nothing exists
                if !File.exist?(location + '/' + filename)
                    File.new(location + '/' + filename, 'w')
                    File.chown(ug_info.uid, ug_info.gid, location + '/' + filename)
                end
            end
        end

        # Valdiate gamefiles and modfiles
        def self.validate_gamefiles(validate_status)
            return false unless validate_status
            LOG.info("Validating gamefiles and mods, this can take a while.")
            `arkmanager update --validate --update-mods`
        end

        
        def self.install_server()
            # Need to check if the install directories are empty first off
            if File.directory?("/server/ARK/") && File.directory?("/server/ARK-Backups/")
                LOG.info("ARK directories already present, skipping install.")
                return false
            end
            # Ensure directory permissions are OK to install as steam
            LOG.info("Making install directories, and setting permissions.")
            FileManipulator.ensure_file('/server/ARK')
            FileManipulator.ensure_file('/server/ARK-Backups')
            FileManipulator.ensure_file('/home/steam/Steam/steamapps/workshop')
            # Create an ark instance | only one instance per container
            LOG.info("Starting install of ARK.")
            LOG.info(`#{STEAMCMD} +login #{Arkswarm.config['steamuser']} +force_install_dir /server +app_update 376030 +quit`)
            LOG.info("Ark install completed.")
            return true
        end
    end
end

