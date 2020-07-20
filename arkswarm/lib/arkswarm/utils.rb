module Arkswarm
  module Util
    # Makes a nested copy of an object
    def self.deep_copy(obj)
      return Marshal.load(Marshal.dump(obj))
    end

    # Replaces the hash without the given keys.
    def self.hash_remove_keys(hash, *keys)
      new_h = deep_copy(hash)
      keys.each { |key| new_h.delete(key) }
      return new_h
    end

    # Selects a key/value array pair, from the array
    def self.arr_select(arr, *keys)
      return [] if arr.nil?

      LOG.debug("Selecting #{keys} in #{arr}")
      results = []
      keys.each do |key|
        LOG.debug("Selecting for #{key}")
        results << arr.select { |v| v.include?(key) }
      end
      LOG.debug("Returning selected entries: #{results}")
      return results
    end

    # Selects a section from the content hash
    def self.hash_select(hash, *keys)
      return {} if hash.nil?

      LOG.debug("Checking for #{keys} in #{hash.keys}")
      results = {}
      keys.each do |key|
        LOG.debug("Selecting for #{key}")
        hash.each do |k, v|
          results[key] = v if k == key
        end
      end
      LOG.debug("Returning selected entries: #{results}")
      return results
    end

    # Checks the truthiness of an object
    def self.true?(obj)
      return obj.to_s.downcase == 'true'
    end
  end
end
