module TSparser
  # ARIB String class.
  # This is following ARIB STD-B24, 2-7
  class AribString
    include AribStringDecoder

    def initialize(binary)
      @binary = binary
    end

    def to_utf_8
      @binary.strip
      # return @utf_8_string ||= decode(@binary)
    end

    # ------------------------------------------------------------
    # Define default setting.
    # This is following definition of ARIB STD-B24, 2-7 Table8-2.
    # Note: G3 in group_map seems to be KATAKANA although this is defined to be MACRO on Table8-2.
    # ------------------------------------------------------------

    def_default_group_map do
      {
        G0: :KANJI,
        G1: :ALPHABET,
        G2: :HIRAGANA,
        G3: :KATAKANA
      }
    end

    def_default_region_map do
      {
        GL: :G0,
        GR: :G2
      }
    end

    # ------------------------------------------------------------
    # Define C0 and C1 control code.
    # This is following definition of ARIB STD-B24, 2-7 Table7-14.
    # ------------------------------------------------------------

    def_control_code(:C0) do
      set :NUL,  0x00, :nothing
      set :BEL,  0x07, :putstr, '[BEL]'
      set :APB,  0x08, :putstr, '[APB]'
      set :APF,  0x09, :putstr, ' '
      set :APD,  0x0A, :putstr, "\n"
      set :APU,  0x0B, :putstr, 'APU'
      set :CS,   0x0C, :putstr, '[CLS]'
      set :APR,  0x0D, :putstr, "\n"
      set :PAPF, 0x16, :exec, 1, proc { |p1| putstr("[PAPF:#{p1}") }
      set :CAN,  0x18, :putstr, '[CAN]'
      set :APS,  0x1C, :exec, 2, proc { |p1, p2| putstr("[APS:#{p1}-#{p2}") }
      set :RS,   0x1E, :nothing
      set :US,   0x1F, :nothing
      set :SP,   0x20, :putstr, ' '
    end

    def_control_code(:C1) do
      set :DEL,   0x7F, :nothing
      set :BKF,   0x80, :putstr, '[BKF]'
      set :RDF,   0x81, :putstr, '[RDF]'
      set :GRF,   0x82, :putstr, '[GRF]'
      set :YLF,   0x83, :putstr, '[YLF]'
      set :BLF,   0x84, :putstr, '[BLF]'
      set :MGF,   0x85, :putstr, '[MGF]'
      set :CNF,   0x86, :putstr, '[CNF]'
      set :WHF,   0x87, :putstr, '[WHF]'
      set :SSZ,   0x88, :putstr, '[SSZ]'
      set :MSZ,   0x89, :putstr, '[MSZ]'
      set :NSZ,   0x8A, :putstr, '[NSZ]'
      set :SZX,   0x8B, :exec, 1, proc { |p1| putstr("[SZX:#{p1}]") }
      set :COL,   0x90, :exec, 1, proc { |p1| putstr(p1 == 0x20 ? "[COL:#{p1}-#{read_one}]" : "[COL:#{p1}]") }
      set :FLC,   0x91, :exec, 1, proc { |p1| putstr("[FLC:#{p1}]") }
      set :CDC,   0x92, :exec, 1, proc { |p1| putstr(p1 == 0x20 ? "[CDC:#{p1}-#{read_one}]" : "[CDC:#{p1}]") }
      set :POL,   0x93, :exec, 1, proc { |p1| putstr("[POL:#{p1}") }
      set :WMM,   0x94, :putstr, '[WMM]'
      set :MACRO, 0x95, :exec, 1, proc { |p1|
        mc = read_one
        mc_bytes = []
        mc_bytes << byte until (byte = read_one) == 0x95
        putstr("[MACRO:#{p1}][MC:#{mc}-#{mc_bytes.join(' ')}][MACRO:#{read_one}]")
      }
      set :HLC,   0x97, :exec, 1, proc { |p1| putstr("[HLC:#{p1}]") }
      set :RPC,   0x98, :exec, 1, proc { |p1| putstr("[RPC:#{p1}]") }
      set :SPL,   0x99, :putstr, '[SPL]'
      set :STL,   0x9A, :putstr, '[STL]'
      set :CSI,   0x9B, :putstr, '[CSI]'
      set :TIME,  0x9D, :exec, 2, proc { |p1, p2| putstr("[TIME:#{p1}-#{p2}") }
      set :SP2,   0xA0, :putstr, ' '
      set :DEL2,  0xFF, :nothing
    end

    # ------------------------------------------------------------
    # Define code-call.
    # This is following definition of ARIB STD-B24, 2-7 Table7-1.
    # ------------------------------------------------------------

    def_code_call do
      set :LS0,  [0x0F],      :G0, :GL, :locking
      set :LS1,  [0x0E],      :G1, :GL, :locking
      set :LS2,  [ESC, 0x6E], :G2, :GL, :locking
      set :LS3,  [ESC, 0x6F], :G3, :GL, :locking
      set :LS1R, [ESC, 0x7E], :G1, :GR, :locking
      set :LS2R, [ESC, 0x7D], :G2, :GR, :locking
      set :LS3R, [ESC, 0x7C], :G3, :GR, :locking
      set :SS2,  [0x19],      :G2, :GL, :single
      set :SS3,  [0x1D],      :G3, :GL, :single
    end

    # ------------------------------------------------------------
    # Define code-operation.
    # This is following definition of ARIB STD-B24, 2-7 Table7-2.
    # ------------------------------------------------------------

    def_code_operation do
      set [ESC, 0x28, :F],             :G_SET, :G0
      set [ESC, 0x29, :F],             :G_SET, :G1
      set [ESC, 0x2A, :F],             :G_SET, :G2
      set [ESC, 0x2B, :F],             :G_SET, :G3

      set [ESC, 0x24, :F],             :G_SET, :G0
      set [ESC, 0x24, 0x29, :F],       :G_SET, :G1
      set [ESC, 0x24, 0x2A, :F],       :G_SET, :G2
      set [ESC, 0x24, 0x2B, :F],       :G_SET, :G3

      set [ESC, 0x28, 0x20, :F],       :DRCS,  :G0
      set [ESC, 0x29, 0x20, :F],       :DRCS,  :G1
      set [ESC, 0x2A, 0x20, :F],       :DRCS,  :G2
      set [ESC, 0x2B, 0x20, :F],       :DRCS,  :G3

      set [ESC, 0x24, 0x28, 0x20, :F], :DRCS,  :G0
      set [ESC, 0x24, 0x29, 0x20, :F], :DRCS,  :G1
      set [ESC, 0x24, 0x2A, 0x20, :F], :DRCS,  :G2
      set [ESC, 0x24, 0x2B, 0x20, :F], :DRCS,  :G3
    end

    # ------------------------------------------------------------
    # Define code-set.
    # This is following definition of ARIB STD-B24, 2-7 Table7-3.
    # ------------------------------------------------------------

    def_code_set(:G_SET) do
      set :KANJI,                 0x42, 2
      set :ALPHABET,              0x4A, 1
      set :HIRAGANA,              0x30, 1
      set :KATAKANA,              0x31, 1
      set :MOSAIC_A,              0x32, 1
      set :MOSAIC_B,              0x33, 1
      set :MOSAIC_C,              0x34, 1
      set :MOSAIC_D,              0x35, 1
      set :PROPORTIONAL_ALPHABET, 0x36, 1
      set :PROPORTIONAL_HIRAGANA, 0x37, 1
      set :PROPORTIONAL_KATAKANA, 0x38, 1
      set :JIS_X0201_KATAKANA,    0x49, 1
      set :JIS_KANJI_1,           0x39, 2
      set :JIS_KANJI_2,           0x3A, 2
      set :ADDITIONAL_SYMBOL,     0x3B, 2
    end

    def_code_set(:DRCS) do
      set :DRCS_0,  0x40, 2
      set :DRCS_1,  0x41, 1
      set :DRCS_2,  0x42, 1
      set :DRCS_3,  0x43, 1
      set :DRCS_4,  0x44, 1
      set :DRCS_5,  0x45, 1
      set :DRCS_6,  0x46, 1
      set :DRCS_7,  0x47, 1
      set :DRCS_8,  0x48, 1
      set :DRCS_9,  0x49, 1
      set :DRCS_10, 0x4A, 1
      set :DRCS_11, 0x4B, 1
      set :DRCS_12, 0x4C, 1
      set :DRCS_13, 0x4D, 1
      set :DRCS_14, 0x4E, 1
      set :DRCS_15, 0x4F, 1
      set :MACRO,   0x70, 1
    end

    # ------------------------------------------------------------
    # Define code.
    # This is following definition of ARIB STD-B24, 2-7
    # ------------------------------------------------------------

    def_code(2, :KANJI) do |byte1, byte2|
      output_jis_zenkaku(byte1, byte2)
    end

    def_code(1, :ALPHABET) do |byte|
      output_jis_ascii(byte)
    end

    def_code(1, :HIRAGANA) do |byte|
      if byte >= 0x77 && alter_byte = HIRAGANA_ARIB_MAP[byte.to_i(0)]
        output_jis_zenkaku(0x21, alter_byte)
      else
        output_jis_zenkaku(0x24, byte)
      end
    end

    def_code(1, :KATAKANA) do |byte|
      if byte >= 0x77 && alter_byte = KATAKANA_ARIB_MAP[byte.to_i(0)]
        output_jis_zenkaku(0x21, alter_byte)
      else
        output_jis_zenkaku(0x25, byte)
      end
    end

    def_code(1, :MOSAIC_A, :MOSAIC_B, :MOSAIC_C, :MOSAIC_D) do
      output_str('??')
    end

    def_code(1, :PROPORTIONAL_ALPHABET) do |byte|
      assign :ALPHABET, byte
    end

    def_code(1, :PROPORTIONAL_HIRAGANA) do |byte|
      assign :HIRAGANA, byte
    end

    def_code(1, :PROPORTIONAL_KATAKANA) do |byte|
      assign :KATAKANA, byte
    end

    def_code(1, :JIS_X0201_KATAKANA) do |byte|
      output_jis_hankaku(byte)
    end

    def_code(2, :JIS_KANJI_1, :JIS_KANJI_2) do |byte1, byte2|
      assign :KANJI, byte1, byte2
    end

    def_code(2, :ADDITIONAL_SYMBOL) do |*bytes|
      if alter_str = ADDITIONAL_SYMBOL_MAP[bytes.map { |b| b.to_i(0) }]
        output_str(alter_str)
      else
        output_str("[unknown: 0x#{bytes[0].dump}, 0x#{bytes[1].dump}]")
      end
    end

    def_code(2, :DRCS_0) do
      output_str('??')
    end

    def_code(1, :DRCS_1, :DRCS_2, :DRCS_3, :DRCS_4, :DRCS_5, :DRCS_6, :DRCS_7, :DRCS_8,
             :DRCS_9, :DRCS_10, :DRCS_11, :DRCS_12, :DRCS_13, :DRCS_14, :DRCS_15, :MACRO) do
      output_str('??')
    end

    # ------------------------------------------------------------
    # Define mapping.
    # ------------------------------------------------------------

    def_mapping(:HIRAGANA_ARIB_MAP) do
      {
        0x77 => 0x35,
        0x78 => 0x36,
        0x79 => 0x3C,
        0x7A => 0x23,
        0x7B => 0x56,
        0x7C => 0x57,
        0x7D => 0x22,
        0x7E => 0x26
      }
    end

    def_mapping(:KATAKANA_ARIB_MAP) do
      {
        0x77 => 0x33,
        0x78 => 0x34,
        0x79 => 0x3C,
        0x7A => 0x23,
        0x7B => 0x56,
        0x7C => 0x57,
        0x7D => 0x22,
        0x7E => 0x26
      }
    end

    def_mapping(:ADDITIONAL_SYMBOL_MAP) do
      {
        [0x7A, 0x50] => '【HV】',
        [0x7a, 0x51] => '【SD】',
        [0x7a, 0x52] => '【P】',
        [0x7a, 0x53] => '【W】',
        [0x7a, 0x54] => '【MV】',
        [0x7a, 0x55] => '【手】',
        [0x7a, 0x56] => '【字】',
        [0x7a, 0x57] => '【双】',
        [0x7a, 0x58] => '【デ】',
        [0x7a, 0x59] => '【S】',
        [0x7a, 0x5A] => '【二】',
        [0x7a, 0x5B] => '【多】',
        [0x7a, 0x5C] => '【解】',
        [0x7a, 0x5D] => '【SS】',
        [0x7a, 0x5E] => '【B】',
        [0x7a, 0x5F] => '【N】',
        [0x7a, 0x60] => '■',
        [0x7a, 0x61] => '●',
        [0x7a, 0x62] => '【天】',
        [0x7a, 0x63] => '【交】',
        [0x7a, 0x64] => '【映】',
        [0x7a, 0x65] => '【無】',
        [0x7a, 0x66] => '【料】',
        [0x7a, 0x67] => '【鍵】',
        [0x7a, 0x68] => '【前】',
        [0x7a, 0x69] => '【後】',
        [0x7a, 0x6A] => '【再】',
        [0x7a, 0x6B] => '【新】',
        [0x7a, 0x6C] => '【初】',
        [0x7a, 0x6D] => '【終】',
        [0x7a, 0x6E] => '【生】',
        [0x7a, 0x6F] => '【販】',
        [0x7a, 0x70] => '【声】',
        [0x7a, 0x71] => '【吹】',
        [0x7a, 0x72] => '【PPV】'
      }
    end
  end
end
