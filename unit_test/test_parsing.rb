# -*- coding: utf-8 -*-
LIBRARY_ROOT_PATH = File.dirname(File.expand_path(File.dirname(__FILE__)))

module TSparser
  module UnitTest
    require 'test/unit'

    # load testing target
    require LIBRARY_ROOT_PATH + '/lib/binary.rb'
    require LIBRARY_ROOT_PATH + '/lib/parsing.rb'

    class ParsingTest < Test::Unit::TestCase
      
      def setup
        @test_class = Class.new do
          include Parsing
        end
      end

      def test_use1
        @test_class.def_parsing do
          read :attr1, Integer, 8
          read :attr2, Binary,  8
        end
        
        binary = make_binary(0b10000001, 0b01111110)
        parsed_data = @test_class.new(binary)
        assert_equal(0b10000001, parsed_data.attr1)
        assert_equal(0b01111110, parsed_data.attr2.to_i(0))
      end

      def test_use2
        @test_class.def_parsing do
          read :attr1, Integer, 8
          read :attr2, Binary,  attr1
        end
        
        binary = make_binary(8, 0b01111110)
        parsed_data = @test_class.new(binary)
        assert_equal(8, parsed_data.attr1)
        assert_equal(0b01111110, parsed_data.attr2.to_i(0))
        assert_raise(NoMethodError) do
          parsed_data.attr3
        end
      end

      def test_undef_parsing
        binary = make_binary(8, 0b01111110)
        parsed_data = @test_class.new(binary)
      end

      # helper methods

      def make_binary(*integers)
        return Binary.new(integers.pack("C*"))
      end
    end
  end
end
