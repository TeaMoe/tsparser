module TSparser
  class Binary < ::String
    class BinaryException < StandardError; end

    def self.from_int(*integers)
      new(integers.pack('C*'))
    end

    # "byte_string" is string encoded as ASCII_8BIT (BINARY).
    def initialize(byte_string = nil)
      byte_string ||= ''.encode(Encoding::ASCII_8BIT)
      if byte_string.encoding != Encoding::ASCII_8BIT
        raise BinaryException, "byte_string's encoding should be ASCII_8BIT(BINARY) " +
                               "(this is #{byte_string.encoding})"
      end
      super(byte_string)
    end

    # Return Integer that is converted from bits specified by "bit_range" (arg2) in
    # byte specified by "byte_index" (arg1).
    #
    # *Warning*: Bit index is from right to left. So, LSB's position is 0, MSB's is 7
    def b(byte_index, bit_range = nil)
      byte_num = self[byte_index].unpack1('C')
      return byte_num unless bit_range

      sub_integer(byte_num, bit_range)
    end

    # Get sub-bit of specified integer.
    # == Example:
    #  binary = Binary.new(something_byte_string)
    #  binary.sub_integer(0b11111100, 1..2) # => 2 (0b10)
    #
    def sub_integer(integer, bit_range)
      bit_range = bit_range..bit_range if bit_range.is_a?(Integer)
      num = 0
      bit_range.reverse_each do |i|
        num = num << 1
        num += integer[i]
      end
      num
    end

    # Return Integer that is converted from Byte at specified position.
    def to_i(byte_position)
      self[byte_position].unpack1('C')
    end

    # Comparator to Integer
    def <=>(other)
      return super unless other.is_a?(Integer)
      raise BinaryException, "Can't compare non-single byte with integer." unless length == 1

      to_i(0) <=> other
    end

    # Generate new Binary instance that is subsequence of self (from specified position to end).
    def from(start_position)
      raise BinaryException, 'starting point must should be less than length' unless start_position < length

      Binary.new(self[start_position, length - start_position])
    end

    # Generate new Binary instance that is subsequence of self (until specified position from start).
    def til(start_position)
      raise BinaryException, 'ending point must should be less than length' unless start_position < length

      Binary.new(self[1, start_position])
    end

    # Generate new Binary instance that is joined from "self", "arg1", "arg2", ... (in order).
    def join(*binaries)
      binaries.inject(self) do |combined, binary|
        Binary.new(combined + binary)
      end
    end

    def &(other)
      raise BinaryException, "Can't apply operator& with integer #{other}." if other < 0x00 || other > 0xFF
      raise BinaryException, "Can't apply operator& on bytes #{self}." if length != 1

      Binary.from_int(to_i(0) & other)
    end

    def dump
      bytes = []
      each_byte do |byte|
        bytes << format('%02X', byte)
      end
      bytes.join(' ')
    end

    # ----------------------------------------------------------------
    # :section: Read methods
    # These methods have access pointer similar to IO#read.
    # ----------------------------------------------------------------

    # Read specified length of bits and return as Integer instance.
    # Bit pointer proceed for that length.
    def read_bit_as_integer(bitlen)
      if length * 8 - bit_pointer < bitlen
        raise BinaryException, "Rest of self length(#{length * 8 - bit_pointer}bit) " +
                               "is shorter than specified bit length(#{bitlen}bit)."
      end
      if bit_pointer % 8 == 0 && bitlen % 8 == 0
        read_byte_as_integer(bitlen / 8)
      else
        response = 0
        bitlen.times do
          response = response << 1
          response += read_one_bit
        end
        response
      end
    end

    # Read specified length of bytes and return as Integer instance.
    # Bit pointer proceed for that length.
    def read_byte_as_integer(bytelen)
      unless bit_pointer % 8 == 0
        raise BinaryException, 'Bit pointer must be pointing start of byte. ' +
                               "But now pointing #{bit_pointer}."
      end
      if length - bit_pointer / 8 < bytelen
        raise BinaryException, "Rest of self length(#{length - bit_pointer / 8}byte) " +
                               "is shorter than specified byte length(#{bytelen}byte)."
      end
      response = 0
      bytelen.times do |i|
        response = response << 8
        response += to_i(bit_pointer / 8 + i)
      end
      bit_pointer_inc(bytelen * 8)
      response
    end

    # Read one bit and return as 0 or 1.
    # Bit pointer proceed for one.
    def read_one_bit
      unless length * 8 - bit_pointer > 0
        raise BinaryException, "Readable buffer doesn't exist" +
                               "(#{length * 8 - bit_pointer}bit exists)."
      end
      response = to_i(bit_pointer / 8)[7 - bit_pointer % 8]
      bit_pointer_inc(1)
      response
    end

    # Read specified length of bits and return as Binary instance.
    # Bit pointer proceed for that length.
    #
    # *Warning*: "bitlen" must be integer of multiple of 8, and bit pointer must be pointing
    # start of byte.
    def read_bit_as_binary(bitlen)
      unless bit_pointer % 8 == 0
        raise BinaryException, 'Bit pointer must be pointing start of byte. ' +
                               "But now pointing #{bit_pointer}."
      end
      unless bitlen % 8 == 0
        raise BinaryException, 'Arg must be integer of multiple of 8. ' +
                               "But you specified #{bitlen}."
      end
      if length - bit_pointer / 8 < bitlen / 8
        raise BinaryException, "Rest of self length(#{length - bit_pointer / 8}byte)" +
                               " is shorter than specified byte length(#{bitlen / 8}byte)."
      end
      response = Binary.new(self[bit_pointer / 8, bitlen / 8])
      bit_pointer_inc(bitlen)
      response
    end

    def read_byte_as_binary(bytelen)
      read_bit_as_binary(bytelen * 8)
    end

    def last_read_byte
      Binary.new(self[bit_pointer - 1])
    end

    # Return whether bit pointer reached end or not (true/false).
    def readable?
      bit_pointer < length * 8
    end

    # Return length of rest readable bit
    def rest_readable_bit_length
      length * 8 - bit_pointer
    end

    def bit_pointer
      @bit_pointer ||= 0
      @bit_pointer
    end

    private

    def bit_pointer_inc(n)
      @bit_pointer ||= 0
      @bit_pointer += n
    end
  end
end
