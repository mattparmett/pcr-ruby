require 'classes/resource'

module PCR
  class CourseHistory
    include PCR::Resource
    attr_reader :course_code, :courses, :id, :path, :retrieved, :valid, :version
    
    def initialize(course_code)
      @course_code = course_code
      
      # Read JSON from PCR API
      json = PCR.get_json("coursehistories/#{self.course_code}")
      
      # List of courses in coursehistory
      @courses = json['result']['courses'].map do |course|
        Course.new(course['path'], course['semester'])
      end

      # Sort course list by semester
      @courses.sort!
      
      # Assign rest of attrs
      attrs = %w(id path reviews retrieved valid version)
      set_attrs(attrs, json)
    end
    
    def recent(metric)
      # Select most recent course
      course = @courses[-1]
      
      # Aggregate ratings for metric
      total, num = 0, 0
      course.sections.each do |section|
        section.reviews.each do |review|
          total += review.send(metric).to_f
          num += 1
        end
      end
      
      # Return average value across most recent sections
      (total / num)
    end
  
    def average(metric)
      # Aggregate ratings across all sections
      total, num = 0, 0
      courses.each do |course|
        course.sections.each do |section|
          section.reviews.each do |review|
            total += review.send(metric).to_f
            num += 1
          end
        end
      end
      
      # Return average value across all sections
      total / num
    end
    
    def name
      self.courses.last.name
    end
  end
end
