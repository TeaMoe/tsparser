# -*- coding: utf-8 -*-
module TSparser
  class ExtendedEventDescriptor
    include Parsing

    def_parsing do
      read :descriptor_tag,         Integer,     8
      read :descriptor_length,      Integer,     8
      read :descriptor_number,      Integer,     4
      read :last_descriptor_number, Integer,     4
      read :iso_639_language_code,  String,     24
      read :length_of_items,        Integer,     8
      read :item_map,               ItemHash,   length_of_items * 8
      read :text_length,            Integer,     8
      read :text,                   AribString, text_length * 8
    end

    class ItemHash
      def initialize(binary)
        @item_map = Hash.new
        while binary.readable?
          item = Item.new(binary)
          @item_map[item.item_description.to_utf_8] = item.item.to_utf_8
        end
      end

      def [](key)
        return @item_map[key]
      end

      def to_h
        return @item_map.dup
      end

      def to_s
        return @item_map.to_s
      end

      class Item
        include Parsing
        
        def_parsing(false) do
          read :item_description_length, Integer,    8
          read :item_description,        AribString, item_description_length * 8
          read :item_length,             Integer,    8
          read :item,                    AribString, item_length * 8
        end
      end
    end
  end
end

