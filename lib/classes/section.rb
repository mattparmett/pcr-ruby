require 'classes/resource'

module PCR
  class Section
    include PCR::Resource
    attr_reader :aliases, :course, :group, :id, :instructors, 
                  :meetingtimes, :name, :path, :reviews, 
                  :sectionnum, :retrieved, :valid, :version

    def initialize(path)
      @path = path

      # Hit api
      json = PCR.get_json(path)

      # Get reviews
      # Usually one, but may be > 1
      @reviews = json['result']['reviews']['values'].map do |review|
        Review.new(review['path'])
      end

      # Assign attrs
      attrs = %w(aliases course group id instructors meetingtimes name 
                 sectionnum retrieved valid version)
      set_attrs(attrs, json)
    end
  end
end
