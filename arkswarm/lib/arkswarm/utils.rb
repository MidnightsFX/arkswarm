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
    end
end
