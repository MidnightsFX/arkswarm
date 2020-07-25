require 'zlib'
require 'fileutils'

module Arkswarm
  module ArkModManager

    def self.apply_mods_to_ark()
      ArkModManager.copy_mods_to_staging_dir()
    end

    # Copys mods to a staging directory for unpacking and building .mod files
    def self.copy_mods_to_staging_dir(source_dir = '/mods/content/346110', target_dir = '/mods/ark_staged')
      FileUtils.cp_r("#{source_dir}/.", target_dir)
    end

    # Unpack the compressed mods, which use unreals file magic signature
    def self.unpack_mods(directory_with_mods = '/mods/ark_staged')
      files_to_decompress = Dir["#{directory_with_mods}/**/*.z"]
      LOG.debug("Files to decompress: #{files_to_decompress}")
      files_to_decompress.each do |file|
        ArkModManager.unpack_compressed_unreal_file(file)
      end
      modmeta_files = Dir["#{directory_with_mods}/**/modmeta.info"]
      modmeta_files.each do |metafile|
        ArkModManager.build_modinfo(metafile)
      end
    end

    def self.build_modinfo(modinfo_file)
      # Unpack Key-Values stored in the modinfo file. This should provide us a mod version.
      LOG.debug("Building modinfo for: #{modinfo_file}")
      modinfo = {}
      File.open(modinfo_file) do |file|
        keypairs = file.read(4).unpack('i')
        keypairs[0].times do
          keysize = file.read(4).unpack('i')
          # LOG.debug("Key Readahead: #{keysize}")
          key = file.read(keysize[0])
          valuesize = file.read(4).unpack('i')
          # LOG.debug("Value Readahead: #{valuesize}")
          value = file.read(valuesize[0])
          LOG.debug("Retrieved: key-#{key} value-#{value}")
          modinfo[key.strip] = value.strip
        end
        break if file.eof?
      end

      File.open(modinfo_file.gsub('modmeta.info', '.modversion'), 'w') do |file|
        modinfo.each do |k, v|
          file.write("#{k}=#{v}\n")
        end
      end
    end

    # Write the modid.mod file, which ARK uses for some reason instead of its provided metafiles...
    def self.write_mod_info(modfolder, modid)
      File.open("#{modfolder}/#{modid}.mod") do |file|
        modid = (-2_147_483_647 + (modid-2_147_483_647) - 2) if modid > 2_147_483_647
        file.write(modid.pack('ixxxx'))

      end
      
    end

    # TODO: Support high chunk compression?
    # Decompresses the unreal engine packed files for mod installation to ARK.
    def self.unpack_compressed_unreal_file(filename)
      File.open(filename) do |file|
        filemagic = file.read(8).unpack('L') # First 8 bytes should always be the Unreal Filemagic
        if filemagic[0] != 2_653_586_369 # 2653586369 with thousand seperators
          LOG.debug("Filemagic: #{filemagic[0]}")
          LOG.error("Staged modfile: #{filename} has bad filemagic. Can't decompress.")
        else
          LOG.debug('Filemagic validated.')
        end
        chunk_lo, chunk_hi, compressed_lo, compressed_hi, uncompressed_lo, uncompressed_hi = file.read(24).unpack('LLLLLL<')
        LOG.debug("24 header: low-#{chunk_lo} high-#{chunk_hi} compressed_low-#{compressed_lo} compressed_high-#{compressed_hi} uncompressed_low-#{uncompressed_lo} uncompressed_high-#{uncompressed_hi}")

        # The following bits build the size of each chunk that we want to work on decompressing.
        chunked_data = 0
        chunks = []
        loop do
          break if chunked_data >= compressed_lo # End once we have run out of things to chunk

          chunk_compress_low, chunk_compress_hi, chunk_uncompress_low, chunk_uncompress_hi = file.read(16).unpack('LLLL<')
          LOG.debug("Chunk: compress_low-#{chunk_compress_low} compress_hi-#{chunk_compress_hi} uncompress_low-#{chunk_uncompress_low} uncompress_hi-#{chunk_uncompress_hi}")
          chunks << chunk_compress_low
          chunked_data += chunk_compress_low
        end
        LOG.debug("Chunks: #{chunks}")
        # Now that we have read the header and chunk map we need to read the content and decompress it.
        uncompressed_file = filename[0..-3]
        LOG.debug("Writing new uncompressed file: #{uncompressed_file}")
        File.open(uncompressed_file, 'w') do |inflated_file|
          zi = Zlib::Inflate.new()
          chunks.each do |chunk_length|
            inflated_content = zi.inflate(file.read(chunk_length))
            # Could log this inflated content here, incase we want to validate it looks like... somthing?
            inflated_file.write(inflated_content)
          end
        end
        expected_uncompressed_size = File.read("#{filename}.uncompressed_size").strip
        uncompressed_size = File.stat(uncompressed_file).size
        LOG.debug("expected uncompressed size: #{expected_uncompressed_size} actual_uncompressed_size: #{uncompressed_size}")
        if expected_uncompressed_size.to_i == uncompressed_size.to_i
          LOG.debug("Expected size validated: #{uncompressed_file}")
        else
          LOG.warn("Filesize does not match expected uncompressed size! File: #{uncompressed_file}")
        end
        # End this loop, log a warning message if the file had content left in the buffer.
        if file.eof?
          LOG.debug("Read all the compressed file data from: #{filename}.")
          break
        else
          LOG.warning("Did not read all data from compressed file. file: #{filename} potentially corrupt.")
        end
      end

      # Delete the compressed file, because we don't care about it anymore!
      File.delete(filename)
    end

    # Travel to the target directory and look at the listed folders for their __modversion__.info files
    def self.get_mod_versions(dir)

    end

    def self.apply_updated_mods(mod_ids, validate)
      mod_ids.each do |mod|
        `#{ArkController.build_steamcmd_request("+workshop_download_item #{ARKID} #{mod} validate")}` if validate
        # cp from source, to arkdir
      end
    end

  end
end
