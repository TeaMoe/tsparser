module TSparser
  class ServiceDescriptionSection
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
      read :transport_stream_id,         Integer,      16
      read :reserved2,                   Integer,       2
      read :version_number,              Integer,       5
      read :current_next_indicator,      Integer,       1
      read :section_number,              Integer,       8
      read :last_section_number,         Integer,       8
      read :original_network_id,         Integer, 16
      read :reserved_future_use2,        Integer, 8
      read :service_descriptions,        ServiceDescriptionList, section_length * 8 - 64 - 32
      read :crc_32, Integer, 32
    end
  end
end
