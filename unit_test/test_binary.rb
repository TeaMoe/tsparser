# -*- coding: utf-8 -*-
$LIBRARY_ROOT_PATH = File.dirname(File.expand_path(File.dirname(__FILE__)))

module TSparser
  module UnitTest
    require 'test/unit'

    # load testing target
    require $LIBRARY_ROOT_PATH + '/lib/binary.rb'

    class BinaryTest < Test::Unit::TestCase
      
      def test_initialize_about_argument_encoding
        assert_raise(Binary::BinaryException) do
          Binary.new(dummy_utf_8_str)
        end
        assert_nothing_raised do
          Binary.new(dummy_ascii_8bit_str)
        end
      end
      
      def test_sub_integer
        binary = Binary.new(dummy_ascii_8bit_str)
        i = 0b11110000
        assert_equal(0b11110000, binary.sub_integer(i, 0..7))
        assert_equal(0b1110000, binary.sub_integer(i, 0..6))
        assert_equal(0b1111000, binary.sub_integer(i, 1..7))
        assert_equal(0b10, binary.sub_integer(i, 3..4))
        assert_equal(0b1, binary.sub_integer(i, 4))
      end

      def test_b
        binary = make_binary(0b10000001, 0b00000000, 0b11111111, 0b01010101)
        assert_equal(0b10000001, binary.b(0))
        assert_equal(0b00000000, binary.b(1))
        assert_equal(0b11111111, binary.b(2))
        assert_equal(0b01010101, binary.b(3))
        assert_equal(0b1, binary.b(0, 7))
      end

      def test_from
        binary = make_binary(0b10000001, 0b00000000, 0b11111111, 0b01010101)
        assert_equal(0b00000000, binary.from(1).b(0))
        assert_raise(Binary::BinaryException) do
          binary.from(4)
        end
      end

      def test_join
        binary1 = make_binary(0b10000001, 0b00000000)
        binary2 = make_binary(0b11111111)
        binary3 = make_binary(0b01010101)
        assert_equal(4, binary1.join(binary2, binary3).size)
        assert_equal(0b01010101, binary1.join(binary2, binary3).b(3))
      end

      def test_to_i
        binary = make_binary(0b10000001, 0b00000000, 0b11111111, 0b01010101)
        assert_equal(0b10000001, binary.to_i(0))
        assert_equal(0b00000000, binary.to_i(1))
        assert_equal(0b11111111, binary.to_i(2))
        assert_equal(0b01010101, binary.to_i(3))
      end

      def test_read_one_bit
        binary = make_binary(0b10000001, 0b01111110)
        ans = [1, 0, 0, 0, 0, 0, 0, 1] + [0, 1, 1, 1, 1, 1, 1, 0]
        ans.each do |a|
          assert_equal(a, binary.read_one_bit)
        end
        assert_raise(Binary::BinaryException) do
          binary.read_one_bit
        end
      end

      def test_read_bit_as_binary_single_use
        binary = make_binary(0b10000001, 0b01111110, 0b11111111, 0b00000000)
        assert_raise(Binary::BinaryException) do
          binary.read_bit_as_binary(7)
        end
        b1 = binary.read_bit_as_binary(16)
        assert_equal(2, b1.length)
        assert_equal(0b01111110, b1.to_i(1))
        assert_raise(Binary::BinaryException) do
          binary.read_bit_as_binary(24)
        end
        assert_equal(0b11111111, binary.read_bit_as_binary(16).to_i(0))
      end

      def test_read_bit_as_binary_with_read_one_bit
        binary = make_binary(0b10000001, 0b01111110)
        binary.read_one_bit
        assert_raise(Binary::BinaryException) do
          binary.read_bit_as_binary(8)
        end
        7.times{ binary.read_one_bit }
        assert_equal(0b01111110, binary.read_bit_as_binary(8).to_i(0))
      end

      def test_read_byte_as_integer
        binary = make_binary(0b10000001, 0b01111110)
        assert_raise(Binary::BinaryException) do
          binary.read_byte_as_integer(3)
        end
        assert_equal(0b1000000101111110, binary.read_byte_as_integer(2))
        assert_raise(Binary::BinaryException) do
          binary.read_byte_as_integer(1)
        end
      end

      def test_read_bit_as_integer
        binary = make_binary(0b10000001, 0b01111110, 0b11111111)
        assert_raise(Binary::BinaryException) do
          binary.read_bit_as_integer(25)
        end
        assert_equal(0b100000, binary.read_bit_as_integer(6))
        assert_equal(0b01011111, binary.read_bit_as_integer(8))
        assert_equal(0b10, binary.read_bit_as_integer(2))
        assert_equal(0b11111111, binary.read_bit_as_integer(8))
        assert_raise(Binary::BinaryException) do
          binary.read_bit_as_integer(1)
        end
      end

      def test_readable
        binary = make_binary(0b00000000)
        assert_equal(true, binary.readable?)
        7.times{ binary.read_one_bit }
        assert_equal(true, binary.readable?)
        binary.read_one_bit
        assert_equal(false, binary.readable?)
      end

      def test_rest_readable_bit_length
        binary = make_binary(0b10000001, 0b01111110)
        assert_equal(16, binary.rest_readable_bit_length)
        binary.read_byte_as_integer(1)
        assert_equal(8, binary.rest_readable_bit_length)
        binary.read_bit_as_integer(3)
        assert_equal(5, binary.rest_readable_bit_length)
        binary.read_bit_as_integer(binary.rest_readable_bit_length)
        assert_equal(0, binary.rest_readable_bit_length)
      end

      def test_rocket_op
        binary = make_binary(3)
        assert(binary < 4)
        assert(binary > 2)
        assert(binary <= 3)
        assert(binary >= 3)
      end

      def test_from_int
        binary = Binary.from_int(0x0F, 0xF0)
        assert_equal(4, binary.b(1, 2..4))
      end

      def test_single_and
        binary = Binary.from_int(0b11111111)
        assert_equal(0b01111111, (binary & 0x7F).to_i(0))
      end


      # helper methods

      def make_binary(*integers)
        return Binary.new(integers.pack("C*"))
      end
        
      def dummy_utf_8_str
        return "dummy utf-8 string".force_encoding(Encoding::UTF_8)
      end

      def dummy_ascii_8bit_str
        return "dummy ascii_8bit string".force_encoding(Encoding::ASCII_8BIT)
      end
    end
  end
end
