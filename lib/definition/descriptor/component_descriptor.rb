# -*- coding: utf-8 -*-
module TSparser
  class ComponentDescriptor
    include Parsing

    def_parsing do
      read :descriptor_tag,        Integer,     8
      read :descriptor_length,     Integer,     8
      read :reserved_future_use,   Binary,      4
      read :stream_content,        Integer,     4
      read :component_type,        Integer,     8
      read :component_tag,         Integer,     8
      read :iso_639_language_code, String,     24
      read :text,                  AribString, descriptor_length * 8 - 48
    end
  end
end

