# -*- coding: utf-8 -*-
module TSparser
  class EITEventList
    include Enumerable
    
    def initialize(binary)
      @events = []
      while binary.readable?
        @events << EITEvent.new(binary)
      end
    end

    def each(&block)
      @events.each(&block)
    end
  end
end
