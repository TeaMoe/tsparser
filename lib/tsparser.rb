# -*- coding: utf-8 -*-
module TSparser
  extend self

  LIBRARY_ROOT_PATH = File.expand_path(File.dirname(__FILE__))

  MAIN_FILES =
    ['/binary.rb',
     '/parsing.rb',
     '/ts.rb',
     '/psi_section_reader.rb',
     '/arib_string_decoder.rb',
     '/epg.rb'
    ]


  DEFINITION_DESCRIPTOR_FILES =
    ['/short_event_descriptor.rb',
     '/extended_event_descriptor.rb',
     '/component_descriptor.rb',
     '/content_descriptor.rb',
     '/digital_copy_control_descriptor.rb',
     '/audio_component_descriptor.rb',
     '/data_content_descriptor.rb',
     '/ca_contract_information_descriptor.rb',
     '/event_group_descriptor.rb',
     '/unknown_descriptor.rb'
    ]

  DEFINITION_FILES =
    ['/descriptor.rb',
     '/descriptor_list.rb',
     '/eit_event.rb',
     '/event_information_section.rb',
     '/event_list.rb',
     '/transport_packet.rb',
     '/arib_duration.rb',
     '/arib_time.rb',
     '/arib_string.rb'
    ]

  MAIN_FILES.each do |path|
    require LIBRARY_ROOT_PATH + path
  end

  DEFINITION_DESCRIPTOR_FILES.each do |path|
    require LIBRARY_ROOT_PATH + '/definition/descriptor' + path
  end

  DEFINITION_FILES.each do |path|
    require LIBRARY_ROOT_PATH + '/definition' + path
  end

  def parse_epg(input)
    epg = EPG.new
    section_stream = PSISectionReader.new(0x12, open_ts(input))
    while section_binary = section_stream.read
      next unless EventInformationSection.section_length_enough?(section_binary)        
      eis = EventInformationSection.new(section_binary)
      epg = epg + eis.to_epg
    end
    return epg
  end

  def open_ts(input)
    case input
    when String
      return TS.new(File.open(input, "rb"))
    when IO
      return TS.new(input)
    else
      raise "arugument should be TS file path(String) or IO"
    end
  end
end
