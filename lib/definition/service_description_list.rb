module TSparser
  class ServiceDescriptionList
    include Enumerable

    def initialize(binary)
      @events = []
      @events << ServiceDescription.new(binary) while binary.readable?
    end

    def each(&block)
      @events.each(&block)
    end
  end
end
