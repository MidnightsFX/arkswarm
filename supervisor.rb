#! /usr/local/bin/ruby

# Helps ensure that messages are sent as they are generated not on completion of command
$stdout.sync = true

# Handle being told to kill the container
Signal.trap("TERM") {
  puts 'Recieved shutdown, starting shutdown.'
  `arkmanager stop --saveworld`
  puts 'Saved and shutdown, exiting.'
  exit
}

# walks the filepath and if there is no file/folder there it will generate them, does nothing if they exist
def ensure_file(location, filename)
  ug_info = File.stat('/server/ARK/game/PackageInfo.bin')
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

# This will take all ENV variables with game_ and use them to generate a configuration
def gen_arkmanager_conf(ark_mgr_dir)
  ensure_file(ark_mgr_dir, 'main.cfg')
  arkmanager_keys = []
  ENV.keys.each do |key|
    arkmanager_keys << key if key.include?('arkopt_')
    arkmanager_keys << key if key.include?('ark_')
    arkmanager_keys << key if key.include?('arkflag_')
  end

  File.open("#{ark_mgr_dir}/main.cfg", 'w') do |file|
    file.write("################################################\n")
    file.write("# This file is was auto-generated #{Time.now}\n")
    file.write("# it will be regenerated next application start\n")
    file.write("################################################\n")
    file.write("arkserverroot=/server/ARK/game\n")
    arkmanager_keys.each do |key|
      file.write("#{key.gsub('arkopt_', '').gsub('ark_', '').gsub('arkflag_', '')}=\"#{ENV[key]}\"\n")
    end
  end

  puts 'Generated main.cfg Configuration File:'
  puts "#{ark_mgr_dir}/main.cfg"
  puts '-------------------------------------------------------------'
  puts File.readlines("#{ark_mgr_dir}/main.cfg").join.to_s
  puts '-------------------------------------------------------------'
end

def gen_game_conf(ark_cfg_dir)
  ensure_file(ark_cfg_dir, 'Game.ini')
  game_keys = []
  ENV.keys.each do |key|
    game_keys << key if key.include?('arkgame_')
  end

  File.open("#{ark_cfg_dir}/Game.ini", 'w+') do |file|
    file.write("################################################\n")
    file.write("# This file is was auto-generated #{Time.now}\n")
    file.write("# it will be regenerated next application start\n")
    file.write("################################################\n")
    file.write("[/script/shootergame.shootergamemode]\n")
    game_keys.each do |key|
      file.write("#{key.gsub('arkgame_', '')}=#{ENV[key]}\n")
    end
  end

  puts 'Generated Game.ini Configuration File:'
  puts "#{ark_cfg_dir}/Game.ini"
  puts '-------------------------------------------------------------'
  puts File.readlines("#{ark_cfg_dir}/Game.ini").join.to_s
  puts '-------------------------------------------------------------'
end

# This will take all ENV variables with gameuser_ and use them to generate a configuration
def gen_game_user_conf(ark_cfg_dir)
  ensure_file(ark_cfg_dir, 'GameUserSettings.ini')
  game_user_keys = []
  ENV.keys.each {|key| game_user_keys << key.gsub('gameuser_', '') if key.include?('gameuser_') }

  gameuser_confg = File.readlines("#{ark_cfg_dir}/GameUserSettings.ini")
  gameuser_details = {}
  gameuser_confg.each_with_index do |cfg_line, index|
    if cfg_line.include?('[ServerSettings]')
      gameuser_details[:cfg_start] = index
      gameuser_details[:server_settings] = index
    end
  end

  # Config was likely empty and we need a skeleton
  if !gameuser_details[:cfg_start]
    gameuser_details[:cfg_start] = 0
    gameuser_details[:server_settings] = 0
    gameuser_confg = ["[ServerSettings]\n"]
  end

  # Add message about the file being auto generated- if it does not exist
  if gameuser_details[:cfg_start].zero?
    gameuser_confg.unshift("################################################\n")
    gameuser_confg.unshift("# it will be regenerated next application start\n")
    gameuser_confg.unshift("# This file is was auto-generated #{Time.now}\n")
    gameuser_confg.unshift("################################################\n")
    gameuser_details.each do |k, v|
      gameuser_details[k] = v + 4 # We added 4 lines, so all positions shifted
    end
  end

  cfg_to_add = []
  # For every ENV config value we have found, rewrite that configuration line
  game_user_keys.each do |k|
    gameuser_confg.each_with_index do |line, index|
      if line.include?(k.gsub('gameuser_', '').to_s)
        gameuser_confg[index] = "#{line.split('=')[0]}=#{ENV["gameuser_#{k}"]}\n"
        break
      end
      # CFG value not found, make sure it gets added
      cfg_to_add << k if (index + 1) == gameuser_confg.length
    end
  end

  cfg_to_add.each do |k|
    gameuser_confg.insert((gameuser_details[:server_settings] + 1), "#{k}=#{ENV["gameuser_#{k}"]}\n")
  end

  File.open("#{ark_cfg_dir}/GameUserSettings.ini", 'w+') do |file|
    gameuser_confg.each {|line| file.write(line) }
  end

  puts 'Generated GameUserSettings.ini Configuration File:'
  puts "#{ark_cfg_dir}/GameUserSettings.ini"
  puts '-------------------------------------------------------------'
  puts File.readlines("#{ark_cfg_dir}/GameUserSettings.ini").join.to_s
  puts '-------------------------------------------------------------'
end

# Used to set the steam user at runtime, from ENV variables, this is primarily for DLC map dowwnloading.
# REQUIRES steam guard disabled
def set_steam_user(user, pass)
  user = 'anonymous' if user.nil?

  ark_mgr_cfg = File.readlines('/etc/arkmanager/arkmanager.cfg')

  File.open('/etc/arkmanager/arkmanager.cfg', 'w+') do |file|
    ark_mgr_cfg.each do |line|
      if line.start_with?('steamlogin')
        # format for the steam CMD login: user pass, this will probably not handle special characters well
        if user == 'anonymous'
          file.write("steamlogin=anonymous\n")
        else
          file.write("steamlogin=\"#{user} #{pass}\"\n")
        end
      else
        file.write(line)
      end
    end
  end
end


# Need to check if the install directories are empty first off
def install_server()
  if File.directory?("/server/ARK/") && File.directory?("/server/ARK-Backups/")
    puts "ARK directories already present, skipping install."
    return false
  end
  # Ensure directory permissions are OK to install as steam
  puts "Making install directories, and setting permissions."
  `mkdir /server/ARK`
  `mkdir /server/ARK-Backups`
  `chown steam:steam /server/ARK -R`
  # Create an ark instance | only one instance per service
  puts "Starting install of ARK."
  puts `arkmanager install --verbose`
  return true
end

# Run-once check for an update, if an update is available will update and start back up
def check_for_updates
  update_needed = `arkmanager checkupdate`
  mod_update_needed = `arkmanager checkmodupdate --revstatus`
  if update_needed.to_i.zero? && mod_update_needed.to_i.zero?
    puts 'No Update needed, sleeping.'
    return false
  end

  puts 'Update Queued, waiting for the server to empty'
  update_status = `arkmanager update --ifempty --validate --safe --update-mods`
  start_status = `arkmanager start --noautoupdate` # we just updated- no need to update now
  return true
end

def first_run(new_server_status)
  if new_server_status
    puts "Updating ARK"
    puts `arkmanager update --verbose`
    puts "Installing Mods, this can take a while."
    puts `arkmanager installmods --verbose`
  end

  # Check status of the server, this should complain about mods which are not installed if we need to install mods
  srv_status = `arkmanager status`
  puts srv_status.to_s
  if srv_status.include?('is requested but not installed')
    puts "Mods are missing, starting mod install. This can take a while."
    srv_status.split("\n").each do |line|
      if line.include?('is requested but not installed')
        cmd = line.split("'")[1]
        puts "Mod install command running: #{cmd}"
        puts `#{cmd}`
      end
    end
  end

  # Check for game update before starting.
  check_for_updates()

  # TODO: setup a backoff for server restart, and integrate discord messaging on failures
  puts "Starting server."
  start_server = `arkmanager start --alwaysrestart --verbose`
  return start_server
end

# Loops running the server process
def run_server(new_server_status)
  first_run(new_server_status) # this will start up the server, it can take quite a while to update/get started.
  loop do
    36.times do # sleep 3600 # sleep one hour
      puts "#{`arkmanager status`}"
      sleep 100
    end
    # check for updates, restart server if needed, this should block if updates are required
    check_for_updates()
  end
end

# Start by generating or regenerating configurations
# Location for this could be passed in, 
# but should probably be static to line up with how its elsewhere

# Check for steam user (steam user is required to run DLC maps, Extinction, Aberration_P, ScorchedEarth_P)
set_steam_user(ENV['steam_user'], ENV['steam_pass'])

# Generate Arkmanager Config
gen_arkmanager_conf('/etc/arkmanager/instances')

# Check if there is an ARK installation already
new_server_status = install_server()

# Generate Game configurations
config_location = '/server/ARK/game/ShooterGame/Saved/Config/LinuxServer'
gen_game_conf(config_location)
gen_game_user_conf(config_location)

# start service
# check if update is available
#  - wait until server is idle to update
run_server(new_server_status)