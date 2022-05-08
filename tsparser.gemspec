require 'rake'

Gem::Specification.new do |s|
  s.name           = "tsparser"
  s.version        = "0.0.0"
  s.summary        = "Library to read MPEG2-TS." +
                     "Mainly, as japanese digital broadcasting in ARIB-format."
  s.description    = <<-END
      This is a general-purpose MPEG-TS parser.
    END
  s.author         = "rokugatsu"
  s.email          = "sasasawada@gmail.com"
  s.homepage       = "http://github.com/rokugatsu/tsparser"
  s.has_rdoc       = true
  s.files          = FileList['lib/**/*', 'LICENSE', 'README.rdoc']
  s.licenses       = ["MIT-LICENSE"]
  s.require_paths  = ["lib"]
end