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

    def self.start_arkserver_thread()
      thr = Thread.new do
        LOG.debug('Starting Arkserver Thread')
        system(Arkswarm.config[:start_server_cmd])
        LOG.debug('Arkserver Thread exited')
      end
      Arkswarm.set_cfg_value(:arkthread, thr)
      return thr.status
    end
    # Checks for updates for the ARK server, returns status based on the update information.
    def self.check_for_server_updates()
      update_status = `#{ArkController.build_steamcmd_request("+force_install_dir /server +app_info_update 1 +app_status #{ARKID}")}`
      app_info = false
      status_details = { 'needupdate' => true }
      LOG.debug("Update Output: #{update_status}")
      update_status.split("\n").each do |line|
        if line.include?("#{ARKID} already up to date.")
          status_details['needupdate'] = false
          break
        end
        # Not sure these are really the correct statuses to be checking for.
        status_details['needupdate'] = false if line.include?("'#{ARKID}' already up to date.") || line.include?(' update state:  ( No Error )')
        next unless app_info == true || line.empty? || line.include?(' - ')

        if line[0..2] == '   ' && status_details['mounted depots']
          status_details['mounted depots'] += line
          next
        end
        details = line.gsub(' - ', '').split(':')
        status_details[details[0].to_s] = details[1]
      end
      LOG.debug("Update Status for ARK: #{status_details}")
      return update_status
    end

    def self.check_mods_and_update(validate = false)
      update = ArkController.check_for_mod_updates()
      ArkController.apply_updated_mods(update, validate) if update
    end

    def self.check_for_mod_updates()
      return false if Arkswarm.config[:mods].empty? # no mods, no updates

      mod_updates = {}
      update_required = false
      mods_to_update = []
      Arkswarm.config[:mods].each do |modid|
        update_staged_mod = `#{ArkController.build_steamcmd_request("+workshop_download_item #{ARKID} #{modid}")}`
        LOG.debug("Staged Mod-#{modid} updated: #{update_staged_mod}")
        # Probably need to read metadata here and not just download things
        mod_updates[modid.to_s] = update_status
      end

      mod_updates.each do |k, v|
        next unless v == true

        update_required = true
        mods_to_update << k
      end
      unless mods_to_update.empty?
        LOG.debug("Mod Updates required for: #{mods_to_update}")
        return mods_to_update
      end
      return false
    end

    def self.apply_updated_mods(mod_ids, validate)
      mod_ids.each do |mod|
        `#{ArkController.build_steamcmd_request("+workshop_download_item #{ARKID} #{mod} validate")}` if validate
        # cp from source, to arkdir
      end
    end

    # Returns false is no mods missing, else returns missing mods
    def self.check_for_missing_mods()
      missing_mods = []
      Arkswarm.config[:mods].each do |mod_id|
        next if File.file?("/server/ARK/game/ShooterGame/Content/Mods/#{mod_id}/mod.info")

        missing_mods << mod_id
      end
      return missing_mods unless missing_mods.empty?

      return false
    end

    # def self.download_update_mods()
    #     +workshop_download_item 346110 812655342 +quit
    #     +app_update 346110 validate +quit
    # end

    # Install/update &/or validate ARK install
    # TODO: Check success and fail if ark is not installed/updated correctly
    def self.update_install_ark(validate = false)
      val_cmd = 'validate' if validate
      cmd = ArkController.build_steamcmd_request("+force_install_dir /server +app_update #{ARKID} #{val_cmd}")
      # TODO: Ensure that ark is not running during the update
      LOG.info("Updating ARK: #{system(cmd)}")
    end

    def self.build_steamcmd_request(request)
      full_request = []
      full_request << "#{STEAMCMD} +@ShutdownOnFailedCommand 1 +@NoPromptForPassword 1 +login #{Arkswarm.config['steamuser']}"
      full_request << request.to_s
      full_request << '+quit'
      return full_request.join(' ')
    end
  end
end
