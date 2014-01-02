# -*- coding: utf-8 -*-
module TSparser
  class DescriptorContainer
    include Parsing

    # ARIB STD-B10 Table5-3
    DescriptorTable = {
      0x4D => TSparser::ShortEventDescriptor,
      0x4E => TSparser::ExtendedEventDescriptor,
      0x50 => nil,
      0x54 => nil,
      0xC1 => nil,
      0xC4 => nil,
      0xC7 => nil,
      0xCB => nil,
      0xD6 => nil
    }

    def_parsing(false) do
      read :descriptor_tag,    Integer,                         8
      read :descriptor_length, Integer,                         8
      read :descriptor,        DescriptorTable[descriptor_tag], descriptor_length * 8
    end
  
    def descriptor_type
      return DescriptorTable[descriptor_tag]
    end
  end
end
