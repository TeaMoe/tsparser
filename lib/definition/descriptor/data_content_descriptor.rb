# -*- coding: utf-8 -*-
module TSparser
  class DataContentDescriptor
    include Parsing

    def_parsing do
      read :descriptor_tag,    Integer, 8
      read :descriptor_length, Integer, 8
      read :rest,              Binary,  descriptor_length * 8   
    end
  end
end
