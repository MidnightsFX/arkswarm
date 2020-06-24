module Arkswarm
    module Util
        def self.deep_copy(obj)
            return Marshal.load(Marshal.dump(obj))
        end
    end
end
