# -*- coding: utf-8 -*-
module TSparser
  class Binary < ::String

    class BinaryException < StandardError; end

    def self.from_int(*integers)
      return new(integers.pack("C*"))
    end

    # "byte_string" is string encoded as ASCII_8BIT (BINARY).
    def initialize(byte_string=nil)
      byte_string ||= "".encode(Encoding::ASCII_8BIT)
      if byte_string.encoding != Encoding::ASCII_8BIT
        raise BinaryException.new("byte_string's encoding should be ASCII_8BIT(BINARY) " +
                                  "(this is #{byte_string.encoding})")
      end
      super(byte_string)
    end

    # Return Integer that is converted from bits specified by "bit_range" (arg2) in
    # byte specified by "byte_index" (arg1).
    #
    # *Warning*: Bit index is from right to left. So, LSB's position is 0, MSB's is 7
    def b(byte_index, bit_range=nil)
      byte_num = self[byte_index].unpack("C")[0]
      return byte_num unless bit_range
      return sub_integer(byte_num, bit_range)
    end

    # Get sub-bit of specified integer.
    # == Example:
    #  binary = Binary.new(something_byte_string)
    #  binary.sub_integer(0b11111100, 1..2) # => 2 (0b10)
    #
    def sub_integer(integer, bit_range)
      bit_range = bit_range..bit_range if bit_range.kind_of?(Integer)
      num = 0
      bit_range.reverse_each do |i|
        num = num << 1
        num += integer[i]
      end
      return num
    end

    # Return Integer that is converted from Byte at specified position.
    def to_i(byte_position)
      return self[byte_position].unpack("C")[0]
    end

    # Comparator to Integer
    def <=>(integer)
      return super unless integer.is_a?(Integer)
      unless self.length == 1
        raise BinaryException.new("Can't compare non-single byte with integer.")
      end
      return self.to_i(0) <=> integer
    end

    # Generate new Binary instance that is subsequence of self (from specified position to end).
    def from(start_position)
      unless start_position < self.length
        raise BinaryException.new("starting point must should be less than length")
      end
      return self[start_position, self.length - start_position]
    end

    # Generate new Binary instance that is joined from "self", "arg1", "arg2", ... (in order).
    def join(*binaries)
      return binaries.inject(self) do |combined, binary|
        Binary.new(combined + binary)
      end
    end

    def &(byte_integer)
      if byte_integer < 0x00 || byte_integer > 0xFF
        raise BinaryException.new("Can't apply operator& with integer #{byte_integer}.")
      end
      if self.length != 1
        raise BinaryException.new("Can't apply operator& on bytes #{self}.")
      end
      return Binary.from_int(self.to_i(0) & byte_integer)
    end

    def dump
      bytes = []
      each_byte do |byte|
        bytes << sprintf("%02X", byte)
      end
      return bytes.join(" ")
    end

    # ----------------------------------------------------------------
    # :section: Read methods
    # These methods have access pointer similar to IO#read.
    # ----------------------------------------------------------------

    # Read specified length of bits and return as Integer instance.
    # Bit pointer proceed for that length.
    def read_bit_as_integer(bitlen)
      if self.length * 8 - bit_pointer < bitlen
        raise BinaryException.new("Rest of self length(#{self.length * 8 - bit_pointer}bit) "+
                                  "is shorter than specified bit length(#{bitlen}bit).")
      end
      if bit_pointer % 8 == 0 && bitlen % 8 == 0
        return read_byte_as_integer(bitlen/8)
      else
        response = 0
        bitlen.times do
          response = response << 1
          response += read_one_bit
        end
        return response
      end
    end

    # Read specified length of bytes and return as Integer instance.
    # Bit pointer proceed for that length.
    def read_byte_as_integer(bytelen)
      unless bit_pointer % 8 == 0
        raise BinaryException.new("Bit pointer must be pointing start of byte. " +
                                  "But now pointing #{bit_pointer}.")
      end
      if self.length - bit_pointer/8 < bytelen
        raise BinaryException.new("Rest of self length(#{self.length - bit_pointer/8}byte) " + 
                                  "is shorter than specified byte length(#{bytelen}byte).")
      end
      response = 0
      bytelen.times do |i|
        response = response << 8
        response += to_i(bit_pointer/8 + i)
      end
      bit_pointer_inc(bytelen * 8)
      return response
    end

    # Read one bit and return as 0 or 1.
    # Bit pointer proceed for one.
    def read_one_bit
      unless self.length * 8 - bit_pointer > 0
        raise BinaryException.new("Readable buffer doesn't exist" +
                                  "(#{self.length * 8 - bit_pointer}bit exists).")
      end
      response = to_i(bit_pointer/8)[7 - bit_pointer%8]
      bit_pointer_inc(1)
      return response
    end

    # Read specified length of bits and return as Binary instance.
    # Bit pointer proceed for that length.
    #
    # *Warning*: "bitlen" must be integer of multiple of 8, and bit pointer must be pointing
    # start of byte.
    def read_bit_as_binary(bitlen)
      unless bit_pointer % 8 == 0
        raise BinaryException.new("Bit pointer must be pointing start of byte. " +
                                  "But now pointing #{bit_pointer}.")
      end
      unless bitlen % 8 == 0
        raise BinaryException.new("Arg must be integer of multiple of 8. " +
                                  "But you specified #{bitlen}.")
      end
      if self.length - bit_pointer/8 < bitlen/8
        raise BinaryException.new("Rest of self length(#{self.length - bit_pointer/8}byte)" +
                                  " is shorter than specified byte length(#{bitlen/8}byte).")
      end
      response = self[bit_pointer/8, bitlen/8]
      bit_pointer_inc(bitlen)
      return response
    end

    def read_byte_as_binary(bytelen)
      return read_bit_as_binary(bytelen*8)
    end

    def last_read_byte
      return Binary.new(self[bit_pointer-1])
    end

    # Return whether bit pointer reached end or not (true/false). 
    def readable?
      return bit_pointer < self.length * 8
    end

    # Return length of rest readable bit
    def rest_readable_bit_length
      return self.length * 8 - bit_pointer
    end

    def bit_pointer
      @bit_pointer ||= 0
      return @bit_pointer
    end

    private

    def bit_pointer_inc(n)
      @bit_pointer ||= 0
      @bit_pointer += n
    end
  end
end
