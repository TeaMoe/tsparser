module TSparser
  class ServiceDescriptor
    include Parsing

    def_parsing do
      read :descriptor_tag,               Integer, 8
      read :descriptor_length,            Integer, 8
      read :service_type,                 Integer, 8
      read :service_provider_name_length, Integer, 8
      read :service_provider_name,        String,  service_provider_name_length * 8
      read :service_name_length,          Integer, 8
      read :service_name,                 String,  service_name_length * 8
    end
  end
end
