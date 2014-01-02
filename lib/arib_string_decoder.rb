# -*- coding: utf-8 -*-
module TSparser
  module AribStringDecoder
    ESC = 0x1B

    def decode(binary)
      decoder = self.class.new_decoder
      return decoder.decode(binary).to_s
    end
    
    def self.included(klass)
      klass.extend ClassExtension
    end

    # --------------------------------------------------
    # Module for class extension when AribStringDecoder is included.
    # --------------------------------------------------
    module ClassExtension
      def new_decoder
        args = [@code_caller, @code_operator, @code_set_map, @code_proc_map, @code_length_map,
                @group_map, @region_map, @control_code_map]
        return AribStringDecoder::Decoder.new(*args)
      end

      def def_default_group_map(&block)
        @group_map = block.call
      end

      def def_default_region_map(&block)
        @region_map = block.call
      end        

      def def_control_code(control_code_name, &block)
        @control_code_map ||= Hash.new
        @control_code_map[control_code_name] = AribStringDecoder::Definition::ControlCode.new
        @control_code_map[control_code_name].instance_eval(&block)
      end

      def def_code_call(&block)
        @code_caller = AribStringDecoder::Definition::CodeCaller.new
        @code_caller.instance_eval(&block)
      end

      def def_code_operation(&block)
        @code_operator = AribStringDecoder::Definition::CodeOperator.new
        @code_operator.instance_eval(&block)
      end

      def def_code_set(set_name, &block)
        @code_set_map ||= Hash.new
        @code_set_map[set_name] = AribStringDecoder::Definition::CodeSet.new
        @code_set_map[set_name].instance_eval(&block)
      end

      def def_code(code_length, *code_names, &block)
        @code_proc_map ||= Hash.new
        @code_length_map ||= Hash.new
        code_names.each do |code_name|
          @code_proc_map[code_name] = block
          @code_length_map[code_name] = code_length
        end
      end

      def def_mapping(map_name, &block)
        AribStringDecoder.const_set(map_name, block.call)
      end
    end

    # --------------------------------------------------
    # Classes to retain definition of code.
    # These class's instance is used to define setting in AribString.
    # --------------------------------------------------
    module Definition
      class ControlCode
        def initialize
          @map = Hash.new
        end

        def set(name, code_num, operation_name, *args)
          @map[code_num] = [operation_name, args]
        end

        def match?(byte)
          return !!@map[byte.to_i(0)]
        end

        def get(byte)
          return @map[byte.to_i(0)]
        end
      end

      class CodeCaller
        def initialize
          @map_whole = Hash.new
          @map_part  = Hash.new{0}
        end

        def set(name, seq, group, target_region, call_type)
          seq = seq.map{|int| Binary.from_int(int)}
          @map_whole[seq] = [group, target_region, call_type]
          seq.length.times do |i|
            @map_part[seq[0..i]] += 1
          end
        end

        def candidates(seq)
          return @map_part[seq]
        end

        def pull(seq)
          unless res = @map_whole[seq]
            raise "No call match with #{seq}."
          end
          return res
        end
      end

      class CodeOperator
        def initialize
          @map = Hash.new
          @map_part = Hash.new{0}
        end

        def set(seq, set_name, group_name)
          seq = seq[0..(seq.length-2)].map{|int| Binary.from_int(int)}
          @map[seq] = [set_name, group_name]
          seq.length.times do |i|
            @map_part[seq[0..i]] += 1
          end
        end

        def candidates(seq, set_map)
          res = @map_part[seq]
          set_name, group_name = @map[seq[0..(seq.length-2)]]
          if set_name && set_map[set_name] && set_map[set_name].find_final_code(seq[-1])
            res += 1
          end
          return res
        end

        def pull(seq, set_map)
          set_name, group_name = @map[seq[0..(seq.length-2)]]
          raise "No operation match with #{seq}." unless set_name
          raise "Code set \"#{set_name}\" is undefined." unless set_map[set_name]
          code_name, byte_length = set_map[set_name].find_final_code(seq[-1])
          raise "Terminal symbol \"#{seq[-1]}\" is not found." unless code_name
          return [code_name, group_name]
        end
      end

      class CodeSet
        def initialize
          @final_code_map = Hash.new
        end

        def set(name, final_code, byte_length)
          final_code = Binary.from_int(final_code)
          @final_code_map[final_code] = [name, byte_length]
        end

        def find_final_code(final_code)
          return @final_code_map[final_code]
        end

        def each_code(&block)
          @final_code_map.each_key(&block)
        end
      end
    end

    # --------------------------------------------------
    # Class which is express decoding process.
    # Receive all coding definition object when instance is maked.
    # --------------------------------------------------
    class Decoder
      def initialize(caller, operator, set_map, proc_map, length_map, group_map, region_map, control_code_map)
        @caller     = caller
        @operator   = operator
        @set_map    = set_map
        @proc_map   = proc_map
        @length_map = length_map
        @decoded    = Decoded.new
        @outputer   = CodeOutputer.new(proc_map, @decoded)
        @control_code_processor = ControlCodeProcessor.new(control_code_map, @decoded)
        @current_group_map  = group_map.dup
        @current_region_map = region_map.dup
        @current_single_region_map = Hash.new
      end

      def decode(binary)
        begin
          parse_one(binary) while binary.readable?
        rescue => error
          return @decoded if @decoded.to_s rescue nil
          parse_error(error, binary)
        end
        return @decoded
      end

      def parse_error(error, binary)
        STDERR.puts "Error occurred on the way to decode following bytes."
        STDERR.puts " \"#{binary.dump}\""
        STDERR.puts "Now process pointer is pointing at #{binary.bit_pointer / 8}-th byte."
        begin
          STDERR.puts "Trying to print now decoded string..."
          STDERR.puts "Decoded: \"#{@decoded}\""
        rescue
          STDERR.puts "Sorry, failed."
        end
        raise error
      end

      def parse_one(binary)
        byte = binary.read_byte_as_binary(1)
        if byte >= 0x21 && byte <= 0x7E
          output_code(byte, binary, :GL)
        elsif byte >= 0xA1 && byte <= 0xFE
          output_code(byte, binary, :GR)
        elsif @control_code_processor.match?(byte)
          @control_code_processor.process(byte, binary)
        else 
          parse_control_code(byte, binary)
        end
      end

      def output_code(byte, binary, target)
        code_name = query_code(target)
        if @length_map[code_name] == 1
          byte  &= 0x7F if target == :GR
          @outputer.output(code_name, byte)
        elsif @length_map[code_name] == 2
          byte2 = binary.read_byte_as_binary(1)
          if target == :GR
            byte  &= 0x7F
            byte2 &= 0x7F
          end
          @outputer.output(code_name, byte, byte2)
        else
          raise "Unsupported code length #{@length_map[code_name]} (from #{code_name})."
        end
      end
      
      def parse_control_code(byte, binary)
        control_code = [byte]
        loop do
          caller_candidates   = @caller.candidates(control_code)
          operator_candidates = @operator.candidates(control_code, @set_map)
          if caller_candidates == 0 && operator_candidates == 0
            raise "Unacceptable control code (#{control_code})."
          end
          if caller_candidates == 1 && operator_candidates == 0
            set_target(*@caller.pull(control_code))
            break
          end
          if caller_candidates == 0 && operator_candidates == 1
            set_code_set(*@operator.pull(control_code, @set_map))
            break
          end
          unless binary.readable?
            raise "Binary is finished before accepting some operation code (now: #{control_code})."
          end
          control_code << binary.read_byte_as_binary(1)
        end
      end

      def set_target(group_name, target_region, call_type)
        case call_type
        when :locking
          @current_region_map[target_region] = group_name
        when :single
          @current_single_region_map[target_region] = group_name
        else
          raise "Unsupported call type \"#{call_type}\"."
        end
      end

      def set_code_set(code_name, group_name)
        @current_group_map[group_name] = code_name
      end

      def query_code(region)
        group_name = @current_single_region_map[region] || @current_region_map[region]
        unless group_name
          raise "No group is set to region \"#{region}\"."
        end
        code_name = @current_group_map[group_name]
        unless code_name
          raise "No code is set to group \"#{group_name}\"."
        end
        @current_single_region_map = Hash.new
        return code_name
      end

      # Inner class to process control code(bytes).
      class ControlCodeProcessor
        def initialize(control_code_map, decoded)
          @control_code_map = control_code_map
          @decoded = decoded
        end

        def match?(byte)
          return @control_code_map[:C0].match?(byte) || @control_code_map[:C1].match?(byte)
        end

        def get(byte)
          if @control_code_map[:C0].match?(byte)
            return @control_code_map[:C0].get(byte)
          elsif @control_code_map[:C1].match?(byte)
            return @control_code_map[:C1].get(byte)
          else
            raise "Undefined code #{byte}."
          end
        end

        def process(byte, binary)
          operation_name, args = get(byte)
          @binary = binary
          send(operation_name, *args)
          @binary = nil
        end

        def putstr(str)
          @decoded.push_str(str)
        end

        def read_one
          raise "Binary is not found." unless @binary
          return @binary.read_byte_as_integer(1)
        end

        def exec(arg_num, proc)
          args = []
          arg_num.times{ args << read_one }
          instance_exec(*args, &proc)
        end

        def nothing
        end
      end
      
      # Inner class to output string code(bytes).
      class CodeOutputer
        def initialize(code_proc_map, decoded)
          @code_proc_map = code_proc_map
          @decoded  = decoded
        end

        def output(code_name, *args)
          unless @code_proc_map[code_name]
            raise "Undefined code \"#{code_name}\" is called."
          end
          instance_exec(*args, &@code_proc_map[code_name])
        end

        def output_ascii_code(byte_integer)
          @decoded.push_jis_ascii(Binary.from_int(byte_integer))
        end

        def assign(code_name, *args)
          output(code_name, *args)
        end

        def output_str(string)
          @decoded.push_str(string)
        end

        def output_jis_ascii(byte)
          @decoded.push_jis_ascii(byte)
        end

        def output_jis_hankaku(byte)
          @decoded.push_jis_hankaku(byte)
        end

        def output_jis_zenkaku(byte1, byte2)
          @decoded.push_jis_zenkaku(byte1, byte2)
        end
      end

      # Inner class to retain decoded string.
      class Decoded
        CODE_ASCII, CODE_HANKAKU, CODE_ZENKAKU = :ascii, :hankaku, :zenkaku

        def initialize
          @decoded_utf_8 = "".encode(Encoding::UTF_8)
          @buffer        = Binary.new
        end

        def push_str(string)
          convert_buffer
          @decoded_utf_8 << string
        end

        def push_jis_ascii(byte)
          if code_type_change(CODE_ASCII)
            @buffer << Binary.from_int(ESC, 0x28, 0x42)
          end
          @buffer << byte
        end

        def push_jis_hankaku(byte)
          if code_type_change(CODE_HANKAKU)
            @buffer << Binary.from_int(ESC, 0x28, 0x49)
          end
          @buffer << byte
        end

        def push_jis_zenkaku(byte1, byte2)
          if code_type_change(CODE_ZENKAKU)
            @buffer << Binary.from_int(ESC, 0x24, 0x42)
          end
          @buffer << byte1 << byte2
        end

        def code_type_change(type)
          return false if @buffer_current_code_type == type
          @buffer_current_code_type = type
          return true
        end

        def convert_buffer
          unless @buffer.empty?
            @decoded_utf_8 << @buffer.encode(Encoding::UTF_8, Encoding::ISO_2022_JP)
            @buffer.clear
            @buffer_current_code_type = nil
          end
        rescue => error
          STDERR.puts "Convert error."
          STDERR.puts "Now buffer(binary): #{@bugger.dump}"
          STDERR.puts "Now decoded(utf-8): #{decoded_utf_8}"
          raise error
        end

        def to_s
          convert_buffer
          return @decoded_utf_8
        end
      end
    end
  end
end
