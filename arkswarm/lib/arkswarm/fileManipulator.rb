
module Arkswarm
    module FileManipulator

        # walks the filepath and if there is no file/folder there it will generate them, does nothing if they exist
        def self.ensure_file(location, filename)
            ug_info = File.stat('/home/steam/steamcmd/steamcmd.sh')
            folder_location = '/'
            location.split('/').each do |segment|
                next if segment == '' # skip start or end slashes
                folder_location = folder_location + segment + "/"
                next if Dir.exist?(folder_location) # do nothing if this folder exists
                Dir.mkdir(folder_location)
                File.chown(ug_info.uid, ug_info.gid, folder_location)
            end
            # If the file does not exist make a blank one. This is primarily for first gen, when nothing exists
            if !File.exist?(location + '/' + filename)
                File.new(location + '/' + filename, 'w')
                File.chown(ug_info.uid, ug_info.gid, location + '/' + filename)
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
            `mkdir /server/ARK`
            `mkdir /server/ARK-Backups`
            `chown steam:steam /server/ARK -R`
            `chown steam:steam /server/ARK-Backups -R`
            `chown steam:steam /home/steam/Steam/steamapps/workshop -R`
            # Create an ark instance | only one instance per service
            LOG.info("Starting install of ARK.")
            `arkmanager install --verbose`
            return true
        end
    end
end

