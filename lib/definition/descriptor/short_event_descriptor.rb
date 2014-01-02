# -*- coding: utf-8 -*-
module TSparser
  class ShortEventDescriptor
    include Parsing

    def_parsing do
      read :descriptor_tag,        Integer,     8
      read :descriptor_length,     Integer,     8
      read :iso_639_language_code, String,     24
      read :event_name_length,     Integer,     8
      read :event_name,            AribString, event_name_length * 8
      read :text_length,           Integer,     8
      read :text,                  AribString, text_length * 8
    end
  end
end

