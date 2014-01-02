# -*- coding: utf-8 -*-
module TSparser

  # Define data-structure of transport packet.
  # This is following 
  #  iso13818-1, 2.4.3.2, Table2-2 and 2.4.3.5, Table2-6 (adaptation field).
  class TransportPacket
    include Parsing

    def_parsing do
      read :sync_byte,                    Integer,  8
      read :transport_error_indicator,    Integer,  1
      read :payload_unit_start_indicator, Integer,  1
      read :transport_priority,           Integer,  1
      read :pid,                          Integer, 13
      read :transport_scrambling_control, Integer,  2
      read :adaptation_field_control,     Integer,  2
      read :continuity_counter,           Integer,  4
      if adaptation_field_control[1] == 1
        read :adaptation_field_length, Integer, 8
        if adaptation_field_length > 0
          read :adaptation_field, AdaptationField, adaptation_field_length * 8
        end
      end
      if adaptation_field_control[0] == 1
        read :payload, Binary, rest_all
      end
    end

    # Especial parsing of PID for fast calculation.
    def pid
      return @pid ||= (@binary.b(1, 0..4) << 8) + @binary.b(2)
    end
  end

  # Define data-structure of adaptation field in transport packet.
  # This is following 
  #  iso13818-1, 2.4.3.5, Table2-6.
  class AdaptationField
    include Parsing
    
    def_parsing do
      read :discontinuity_indicator,              Integer, 1
      read :random_acceses_indicator,             Integer, 1
      read :elementary_stream_priority_indicator, Integer, 1
      read :pcr_flag,                             Integer, 1
      read :opcr_flag,                            Integer, 1
      read :splicing_point_flag,                  Integer, 1
      read :transport_private_data_flag,          Integer, 1
      read :adaptation_field_extension_flag,      Integer, 1
      if pcr_flag == 1
        
      end
      if opcr_flag == 1

      end
      if splicing_point_flag == 1

      end
      if transport_private_data_flag == 1

      end
      if adaptation_field_extension_flag == 1

      end
    end
  end
end
