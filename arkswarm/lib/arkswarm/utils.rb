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
        def self.arr_select(arr, keys*)
            results = []
            keys.each do
                results << arr.select { |v| v[0] == key || v[1] == key }
            end
            return results
        end

        # Checks the truthiness of an object
        def self.true?(obj)
            return obj.to_s.downcase == 'true'
        end
    end
end
