module TSparser
  class ServiceDescription
    include Parsing

    # define data-structure of event_information_section
    # this is following ARIB-STD-b10v4_9 - 88p
    def_parsing(false) do
      read :service_id,              Integer,    16
      read :reserved_future_use,     Integer,    6
      read :eit_schedule_flag,       Integer,    1
      read :eit_present_following_flag, Integer, 1
      read :running_status,          Integer,    3
      read :free_CA_mode,            Integer,    1
      read :descriptors_loop_length, Integer,    12
      read :descriptors,             DescriptorList, descriptors_loop_length * 8
    end

    def provider
      descriptors.first.service_provider_name
    end

    def service
      descriptors.first.service_name
    end

    def service_type
      descriptors.first.service_type
    end
  end
end
