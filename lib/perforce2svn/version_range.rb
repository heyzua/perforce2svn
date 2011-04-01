require 'choosy/errors'

module Perforce2Svn
  # Represents the version range that is supposed to be migrated
  class VersionRange
    attr_reader :min, :max
    
    def initialize(min, max=-1)
      @min = min
      @max = max
    end
    
    def reset_to_head(head)
      @max = head
    end
    
    def synced_to_head?
      @max == -1
    end

    def VersionRange.build(versions)
      if versions =~ /^(\d+):(HEAD|\d+)$/
        min = $1.to_i
        if $2 == "HEAD"
          max = -1
        else
          max = $2.to_i
          if max < 1
            raise Choosy::ValidationError, "Maximum change revision cannot be less than 1: #{versions}"
          end
        end
        
        if min < 1
          raise Choosy::ValidationError, "Minimum change revision cannot be less than 1: #{versions}"
        end
        
        return VersionRange.new(min, max)
      else
        raise Choosy::ValidationError, "Missing or malformed argument for '--changes': #{versions}"
      end
    end
  end
end
