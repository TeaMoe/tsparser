# -*- coding: utf-8 -*-
module TSparser
  class AribDuration

    def initialize(binary)
      @hour = binary.read_bit_as_integer(4) * 10 + binary.read_bit_as_integer(4)
      @min  = binary.read_bit_as_integer(4) * 10 + binary.read_bit_as_integer(4)
      @sec  = binary.read_bit_as_integer(4) * 10 + binary.read_bit_as_integer(4)
    end

    def to_s
      return sprintf("%2d:%2d:%2", @hour, @min, @sec)
    end

    def to_sec
      return @hour * 3600 + @min * 60 + @sec
    end
  end
end
