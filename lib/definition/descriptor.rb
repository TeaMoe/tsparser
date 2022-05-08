module TSparser
  class Descriptor
    # ARIB STD-B10 Table5-3
    DescriptorTable = {
      0x4D => TSparser::ShortEventDescriptor,
      0x4E => TSparser::ExtendedEventDescriptor,
      0x48 => TSparser::ServiceDescriptor,
      0x50 => TSparser::ComponentDescriptor,
      0x54 => TSparser::ContentDescriptor,
      0xC1 => TSparser::DigitalCopyControlDescriptor,
      0xC4 => TSparser::AudioComponentDescriptor,
      0xC7 => TSparser::DataContentDescriptor,
      0xCB => TSparser::CAContractInformationDescriptor, # Defined in ARIB STD-B25
      0xD6 => TSparser::EventGroupDescriptor
    }
    DescriptorTable.default = TSparser::UnknownDescriptor

    def self.new(binary)
      now_point               = binary.bit_pointer / 8
      descriptor_tag          = binary.b(now_point + 0)
      descriptor_length       = binary.b(now_point + 1)
      descriptor_whole_binary = binary.read_bit_as_binary(descriptor_length * 8 + 16)
      DescriptorTable[descriptor_tag].new(descriptor_whole_binary)
    end
  end
end
