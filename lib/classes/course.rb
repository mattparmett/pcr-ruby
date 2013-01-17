require 'classes/resource'

module PCR
  class Course
    include Comparable
    include PCR::Resource
    attr_reader :aliases, :credits, :description, :history, :id, 
                  :name, :path, :reviews, :sections, :semester, 
                  :retrieved, :valid, :version

    def initialize(path, semester)
      #TODO: Don't need to pass in semester
      @path, @semester = path, semester

      # Hit api
      json = PCR.get_json(path)

      # List of sections
      @sections = json['result']['sections']['values'].map do |section|
        Section.new(section['path'])
      end

      # Assign attrs
      attrs = %w(aliases credits description history id name reviews 
                 retrieved valid version)
      set_attrs(attrs, json)
    end

    def <=>(other)
      #TODO: Throw error if not same course
      return year <=> other.year unless year == other.year
      season <=> other.season
    end

    def average(metric)
      # Aggregate ratings across all sections
      total, num = 0, 0
      #TODO: inject
      self.sections.each do |section|
        section.reviews.each do |review|
          total += review.send(metric).to_f
          num += 1
        end
      end

      # Return average value across all sections
      (total / num)
    end

    def year
      @semester[0..3].to_i
    end

    def season
      @semester[4]
    end
  end
end
