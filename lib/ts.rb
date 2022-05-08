# -*- coding: utf-8 -*-
module TSparser
  class TS

    def initialize(io, filtering_procs=[])
      @io = io
      @filtering_procs = filtering_procs
    end

    def filter(*pids, &block)
      new_filtering_procs = @filtering_procs
      if pids.length > 0
        new_filtering_procs = [Proc.new{|packet| pids.include?(packet.pid)}] + new_filtering_procs
      end
      if block
        new_filtering_procs = new_filtering_procs + [block]
      end
      return TS.new(@io, new_filtering_procs)
    end

    def read
      loop do
        return nil if eof?
        packet_binary = Binary.new(@io.read(188))
        if packet_binary.length != 188
          raise "Bytes less than 188byte (#{packet_bytes.length}byte) were read from TS file."
        end
        packet = TransportPacket.new(packet_binary)
        return packet if @filtering_procs.all?{|filter| filter.call(packet)}
      end
    end

    def eof?
      return @io.eof?
    end

    def close
      @io.close
    end
  end
end
