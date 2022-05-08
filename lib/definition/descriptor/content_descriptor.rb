# -*- coding: utf-8 -*-
module TSparser
  class ContentDescriptor
    include Parsing

    def_parsing do
      read :descriptor_tag,    Integer,     8
      read :descriptor_length, Integer,     8
      read :contents,          ContentList, descriptor_length * 8
    end

    class ContentList
 
      def initialize(binary)
        @contents = []
        while binary.readable?
          @contents << Content.new(binary)
        end
      end

      def each(&block)
        @contents.each(&block)
      end

      class Content
        include Parsing

        def_parsing do
          read :content_nibble_level_1, Integer, 4
          read :content_nibble_level_2, Integer, 4
          read :user_nibble,            Integer, 4
          read :user_nibble,            Integer, 4
        end
      end
    end
  end
end
