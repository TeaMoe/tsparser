# -*- coding: utf-8 -*-
module TSparser
  class AribTime
    require 'date'
    require 'time'

    def initialize(binary)
      @mjd  = binary.read_byte_as_integer(2)
      @hour = binary.read_bit_as_integer(4) * 10 + binary.read_bit_as_integer(4)
      @min  = binary.read_bit_as_integer(4) * 10 + binary.read_bit_as_integer(4)
      @sec  = binary.read_bit_as_integer(4) * 10 + binary.read_bit_as_integer(4)
    end

    def date
      return @date ||= convert_mjd_to_date(@mjd)
    end

    # ARIB STD-B10 2, appendix-C
    def convert_mjd_to_date(mjd)
      y_ = ((mjd - 15078.2) / 365.25).to_i
      m_ = ((mjd - 14956.1 - (y_ * 365.25).to_i) / 30.6001).to_i
      d  = mjd - 14956 - (y_ * 365.25).to_i - (m_ * 30.6001).to_i
      k  = (m_ == 14 || m_ == 15) ? 1 : 0
      y  = y_ + k
      m  = m_ - 1 - k * 12
      return Date.new(1900 + y, m, d)
    end
    
    def date_str
      return sprintf("%02d/%02d/%02d", date.year, date.month, date.day)
    end
    
    def to_s
      return sprintf("%s %02d:%02d:%02d +0900", date_str, @hour, @min, @sec)
    end

    def to_time
      return Time.parse(to_s)
    end
  end
end
