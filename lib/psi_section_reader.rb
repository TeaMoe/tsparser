module TSparser
  class PSISectionReader
    def initialize(pid, ts)
      @ts = ts.filter(pid)
    end

    def read
      cont_packets = []
      while packet = @ts.read
        if packet.payload_unit_start_indicator == 1
          if @start_packet && continuity_check(@start_packet, *cont_packets, packet)
            binary = @start_packet.payload.from(@start_packet.payload.b(0) + 1)
            binary = binary.join(*cont_packets.map { |packet| packet.payload })
            binary = binary.join(packet.payload.til(packet.payload.b(0)))
            @start_packet = packet
            cont_packets = []
            return binary
          else
            @start_packet = packet
            cont_packets = []
            next
          end
        end
        cont_packets << packet
      end
      nil
    end

    private

    def continuity_check(first_packet, *packets)
      counter = first_packet.continuity_counter
      packets.all? do |packet|
        counter += 1
        packet.continuity_counter == counter % 16
      end
    end
  end
end
