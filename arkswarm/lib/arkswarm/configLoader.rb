module Arkswarm
    module ConfigLoader

        # This takes in an INI file and generates a structure like this:
        # file = { section_header1 => { contents => [ [key, value]... ], keys => [key, key...]}, ... }
        def self.parse_ini_file(filepath)
            file_lines = IO.readlines("#{filepath}", chomp: true)
            LOG.debug("Ingested #{file_lines.length} lines.")
            file_contents = { }
            current_section = ""
            LOG.debug("Starting ingest of #{filepath}")
            file_lines.each_with_index do |line, index|
                LOG.debug(line)
                # If there is a header determining this config file to be a game.ini conf then we use that to set the header, if configs are unordered they will go in here
                if index == 0 && line.strip == #!game
                    LOG.debug("game header found, setting section")
                    current_section = '[/Script/ShooterGame.ShooterGameMode]'
                    file_contents[current_section] = { "content" => [], "keys" => [] }
                end
                
                next if line[0] == "#" && current_section == "" # Skips the generated header, or other header comments

                if line[0] == "[" # new section
                    LOG.debug("New section #{line}")
                    current_section = line
                    file_contents[current_section] = { "content" => [], "keys" => [] }
                else
                    if current_section.empty? # catch for reading in files that have contents outside of header sections, or dont use header sections
                        LOG.debug("Found lines without a section, placing them in ungrouped.")
                        current_section = "ungrouped"
                        file_contents[current_section] = { "content" => [], "keys" => [] }
                    end
                    if line.empty? # keep empty lines but dont multiply or add their keys
                        LOG.debug("Found an empty line, keeping it.")
                        file_contents[current_section]["content"] << ""
                    else
                        LOG.debug("Found a non-empty, non-header line to add to a section: #{line}")
                        line_contents = line.split("=")
                        line_contents << "" if line_contents.length == 1
                        file_contents[current_section]["content"] << line_contents
                        file_contents[current_section]["keys"] << line_contents[0]
                    end
                end
            end
            return file_contents
        end


        def self.discover_configurations(location = '/config')
            return {} unless Dir.exist?(location) # check if /config exists

            # returnable config
            config_mash = {}

            # look at all files & folders
            files = Dir["#{location}/**/*"]
            files.each do |file|
                parsed_file = ConfigLoader.parse_ini_file(file)
                config_mash = ConfigLoader.merge_configs(config_mash, parsed_file)
                LOG.debug("Merging configuration file provided for discovery #{file}")
            end
            LOG.debug("Returning merged configuration with keys: #{config_mash.keys}")
            return config_mash
        end

        def self.merge_configs(primary, secondary)
            return primary if secondary.nil?
            merged_hash = Util.deep_copy(primary)
            LOG.debug("Merging: #{primary.keys} & #{secondary.keys}")
            secondary.each do |key, values|
                if merged_hash.has_key?(key)
                    LOG.debug("primary & secondary key #{key} found merging")
                    # gotta merge in the key
                    secondary[key]['content'].each do |entry|
                        next if entry[0].nil? # nothing to merge if the entry is nil, but how did you get here anyways?
                        LOG.debug("Merging entry: #{entry}")
                        # if the key can be a duplicated, it just gets added 
                        # or if it is a space, it also just gets added, so we can merge configs with spaces in them easier
                        if DUPLICATABLE_KEYS.include?(entry[0]) || entry[0].empty? 
                            LOG.debug("Duplicatable key #{entry[0]} found, adding key")
                            LOG.debug("Adding key #{entry[0]}, adding value #{entry}")
                            merged_hash[key]['keys'] << entry[0] unless primary[key]['keys'].include?(entry[0]) # only need the key, in keys, if this is the first one
                            merged_hash[key]['content'] << entry
                        elsif merged_hash[key]['keys'].include?(entry[0]) # its a non-duplicatable key, that already exists, needs its value updated
                            LOG.debug("Non-duplicatable key #{entry[0]} found, taking preferred value")
                            merged_hash[key]['content'].each do |prime_entry|
                                # LOG.debug("Looking for primary key #{entry[0]} == #{prime_entry[0]} | #{prime_entry[0] == entry[0]}")
                                next unless prime_entry[0] == entry[0]
                                LOG.debug("Found key: Setting #{entry[1]}")
                                prime_entry[1] = entry[1]
                                break
                            end
                        else # the section exists, but doesn't contain the provided key- add it
                            LOG.debug("New key #{entry[0]} found, adding value")
                            merged_hash[key]['keys'] << entry[0]
                            merged_hash[key]['content'] << entry
                        end
                    end
                else
                    # no merge, just add the key and its values
                    merged_hash[key] = values
                end
            end
            return merged_hash
        end

        # Filters through a configuration hash and updates the key which matches the one passed in
        # Returns true/false based on whether an update occured
        def self.update_cfg_value(ini_file_hash, key, value, add = true)
            update_status = false
            ini_file_hash.each do |section, values|
                LOG.debug("Checking for #{key} in section: #{values["keys"]}")
                next unless values["keys"].include?(key)

                values["content"].each do |entry|
                    next unless entry[0] == key

                    entry[1] = value
                    update_status = true
                end
            end
            if add && update_status == false # Add the value into the undefined section, ideally this doesn't need to happen
                if ini_file_hash["ungrouped"]
                    ini_file_hash["ungrouped"]["content"] << [key, value]
                    ini_file_hash["ungrouped"]["keys"] << [key]
                else
                    ini_file_hash["ungrouped"] = { "content" => [[key, value]], "keys" => [key] }
                end
                update_status = true
            end
            return update_status
        end

        # Assembles a configuration file from a config-filehash, can add required lines.
        # Required lines will be added outside of existing headers
        def self.generate_config_file(filehash, file_location = nil)
            contents = []

            contents << "###############################################################"
            contents << "# This file is was auto-generated #{Time.now}"
            contents << "# it will be regenerated next application start"
            contents << "###############################################################"
            filehash.each do |key, values|
                LOG.debug("section #{key} - #{values}")
                contents << key unless key == "ungrouped" # do not write the header for ungrouped values
                values["content"].each do |entry|
                    LOG.debug("writing #{entry}")
                    if entry.empty?
                        contents << ""
                    else
                        contents << "#{entry.join("=")}"
                    end
                end
                # contents << "\n"
            end
            if file_location # write out the content if we are provided a file location
                File.open("#{file_location}", 'w+') do |file|
                    contents.each_with_index do |line, index|
                        file.write("#{line}\n")
                    end
                end
            end
            return contents
        end
    
    end
end
