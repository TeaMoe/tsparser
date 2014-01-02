# -*- coding: utf-8 -*-
module TSparser
  class EPG
    include Enumerable

    def initialize(epg_hash=Hash.new)
      @epg = epg_hash
    end

    def add(event_id, attr_hash)
      @epg[event_id] = attr_hash
    end

    attr_reader :epg

    def +(other)
      new_hash = @epg.merge(other.epg) do |event_id, attr_hash1, attr_hash2|
        attr_hash1.merge(attr_hash2) do |attr_name, val1, val2|
          [val1, val2].max{|a, b| a.to_s.size <=> b.to_s.size}
        end
      end
      return EPG.new(new_hash)
    end

    def each(&block)
      @epg.each_value(&block)
    end
  end
end
