# -*- coding: utf-8 -*-
module TSparser
  module Parsing
    
    def initialize(binary, parsing_proc=nil, delay=true)
      @binary = binary
      @parsed_variable = Hash.new
      if delay
        @parsing_proc = parsing_proc
      else
        self.instance_eval(&parsing_proc) if parsing_proc
      end
    end

    def read(name, type, bit)
      if type == Integer
        val = @binary.read_bit_as_integer(bit)
        @parsed_variable[name] = val
      else
        val = @binary.read_bit_as_binary(bit)
        @parsed_variable[name] = Proc.new{ type.new(val) }
      end
    rescue => error
      STDERR.puts "Parsing error occurred at class: #{self.class}, attr: #{name}(type:#{type}, bitlen:#{bit})"
      raise error
    end

    def rest_all
      return @binary.rest_readable_bit_length
    end

    def method_missing(name, *args)
      if @parsing_proc
        parsing_proc = @parsing_proc
        @parsing_proc = nil
        self.instance_eval(&parsing_proc)
      end
      if @parsed_variable[name]
        if @parsed_variable[name].instance_of?(Proc)
          @parsed_variable[name] = @parsed_variable[name].call
        end
        return @parsed_variable[name]
      end
      super
    end

    def self.included(klass)
      klass.extend ClassExtension
    end

    module ClassExtension

      def def_parsing(delay=true, &block)
        @delay = delay
        @parsing_definition = block
      end

      def new(binary)
        super(binary, @parsing_definition, @delay)
      end
    end
  end
end
