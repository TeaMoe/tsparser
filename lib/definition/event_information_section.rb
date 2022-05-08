module TSparser
  class EventInformationSection
    include Parsing

    def self.section_length_enough?(section_binary)
      section_length = (section_binary.b(1, 0..3) << 8) + section_binary.b(2)
      section_binary.length >= section_length + 3
    end

    # define data-structure of event_information_section
    # this is following ARIB-STD-b10v4_9 - 88p
    def_parsing do
      read :table_id,                    Integer,       8
      read :section_syntax_indicator,    Integer,       1
      read :reserved_future_use,         Integer,       1
      read :reserved1,                   Integer,       2
      read :section_length,              Integer,      12
      read :service_id,                  Integer,      16
      read :reserved2,                   Integer,       2
      read :version_number,              Integer,       5
      read :current_next_indicator,      Integer,       1
      read :section_number,              Integer,       8
      read :last_section_number,         Integer,       8
      read :transport_stream_id,         Integer,      16
      read :original_network_id,         Integer,      16
      read :segment_last_section_number, Integer,       8
      read :last_table_id,               Integer,       8
      read :events,                      EITEventList, section_length * 8 - 88 - 32
      read :crc_32,                      Integer,      32
    end

    def to_epg
      epg = EPG.new
      events.each do |event|
        attr_hash = {
          event_id: event.event_id,
          service_id:,
          start_time: event.start_time.to_s,
          duration: event.duration.to_sec
        }
        event.descriptors.each do |desc|
          case desc
          when ShortEventDescriptor
            attr_hash[:name] = desc.event_name.to_utf_8
            attr_hash[:description] = desc.text.to_utf_8
          end
        end
        epg.add(event.event_id, attr_hash) if attr_hash[:name]
      end
      epg
    end
  end
end
