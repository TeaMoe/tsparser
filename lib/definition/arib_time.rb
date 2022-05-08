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
      @date ||= convert_mjd_to_date(@mjd)
    end

    # ARIB STD-B10 2, appendix-C
    def convert_mjd_to_date(mjd)
      y_ = ((mjd - 15_078.2) / 365.25).to_i
      m_ = ((mjd - 14_956.1 - (y_ * 365.25).to_i) / 30.6001).to_i
      d  = mjd - 14_956 - (y_ * 365.25).to_i - (m_ * 30.6001).to_i
      k  = [14, 15].include?(m_) ? 1 : 0
      y  = y_ + k
      m  = m_ - 1 - k * 12
      Date.new(1900 + y, m, d)
    end

    def date_str
      format('%02d/%02d/%02d', date.year, date.month, date.day)
    end

    def to_s
      format('%s %02d:%02d:%02d +0000', date_str, @hour, @min, @sec)
    end

    def to_time
      Time.parse(to_s)
    end
  end
end
