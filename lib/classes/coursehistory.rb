class CourseHistory < PCR
  attr_accessor :course_code, :courses, :id, :path, :retrieved, :valid, :version
  
  def initialize(course_code, api_endpt, token)
    @course_code = course_code
    @api_endpt = api_endpt
    @token = token
    
    # Read JSON from PCR API
    api_url = makeURL("coursehistories/#{self.course_code}")
    json = JSON.parse(open(api_url).read)
    
    # List of courses in coursehistory
    course_list = json['result']['courses']
    @courses = []
    course_list.each do |course|
      @courses << Course.new(course['path'], course['semester'], @api_endpt, @token)
    end
    # Sort course list by semester
    @courses.sort! { |a,b| a.compareSemester(b) }
    
    # Assign rest of attrs
    attrs = %w(id path reviews retrieved valid version)
    attrs.each do |attr|
      if json['result'][attr]
        self.instance_variable_set("@#{attr}", json['result'][attr])
      else
        self.instance_variable_set("@#{attr}", json[attr])
      end
    end
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
    (total / num)
  end
  
  def name
    self.courses.last.name
  end

end