# -*- coding: utf-8 -*-
module TSparser
  class DescriptorList
    include Enumerable
    
    def initialize(binary)
      @descriptors = []
      while binary.readable?
        @descriptors << Descriptor.new(binary)
      end
    end

    def each(&block)
      @descriptors.each(&block)
    end
  end
end
