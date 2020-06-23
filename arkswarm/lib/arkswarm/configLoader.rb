module Arkswarm
    module ConfigLoader

        # This takes in an INI file and generates a structure like this:
        # file = { section_header1 => { contents => [ [key, value]... ], keys => [key, key...]}, ... }
        def self.parse_ini_file(filepath)
            file_lines = File.readlines("#{filepath}", chomp: true)
            LOG.debug("Ingested #{file_lines.length} lines.")
            file_contents = { }
            current_section = ""
            LOG.debug("Starting ingest of #{filepath}")
            file_lines.each do |line|
                LOG.debug(line)
                next if line[0] == "#" && current_section == "" # Skips the generated header, or other header comments

                if line[0] == "[" # new section
                    current_section = line
                    file_contents[current_section] = { "content" => [], "keys" => [] }
                else
                    if current_section.empty? # catch for reading in files that have contents outside of header sections, or dont use header sections
                        current_section = "ungrouped"
                        file_contents[current_section] = { "content" => [], "keys" => [] }
                    end
                    if line.empty? # keep empty lines but dont multiply or add their keys
                        file_contents[current_section]["content"] << ""
                    else
                        line_contents = line.split("=")
                        file_contents[current_section]["content"] << line_contents
                        file_contents[current_section]["keys"] << line_contents[0]
                    end
                end
            end
            return file_contents
        end


        def self.discover_configurations(location = '/config')
            return false unless Dir.exist?(location) # check if /config exists

            # returnable config
            config_mash = {}

            # look at all files & folders
            files = Dir["#{location}/**/*"]
            files.each do |file|
                parsed_file = ConfigLoader.parse_ini_file(file)
                ConfigLoader.merge_configs!(config_mash, parsed_file)
            end
            return config_mash
        end

        def self.merge_configs!(primary, secondary)
            secondary.each do |key, values|
                if primary.has_key?(key)
                    # gotta merge in the key
                    secondary[key]['content'].each do |entry|
                        if DUPLICATABLE_KEYS.include?(entry[0]) # if the key can be a duplicate, it just gets added
                            primary[key]['keys'] << entry[0] unless primary[key]['keys'].include?(entry[0]) # only need the key, in keys, if this is the first one
                            primary[key]['content'] << entry
                        elsif primary[key]['keys'].include?(entry[0]) # its a non-duplicatable key, that already exists, needs its value updated
                            primary[key]['contents'].each do |prime_entry|
                                next unless prime_entry[0] == entry[0]
                                prime_entry[1] = entry[1] # set the value to the new value
                            end
                        else # the section exists, but doesn't contain the provided key- add it
                            primary[key]['keys'] << entry[0]
                            primary[key]['contents'] << entry
                        end
                    end
                else
                    # no merge, just add the key and its values
                    primary[key] = values
                end
            end
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
