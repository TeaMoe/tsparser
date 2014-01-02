# -*- coding: utf-8 -*-
module TSparser
  class EITEvent
    include Parsing
    
    # define data-structure of event_information_section
    # this is following ARIB-STD-b10v4_9 - 88p
    def_parsing(false) do
      read :event_id,                Integer,        16
      read :start_time,              AribTime,       40
      read :duration,                AribDuration,   24
      read :running_status,          Integer,        3
      read :free_ca_mode,            Integer,        1
      read :descriptors_loop_length, Integer,        12
      read :descriptors,             DescriptorList,  descriptors_loop_length * 8
    end
  end
end



