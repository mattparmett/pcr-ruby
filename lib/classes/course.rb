class Course < PCR
  attr_accessor :course_code, :sections, :id, :name, :path, :reviews
  
  def initialize(course_code)
    if course_code.is_a? String && course_code.isValidCourseCode?
      @course_code = course_code
      
      #Read JSON from the PCR API
      api_url = @@api_endpt + "coursehistories/" + self.course_code + "/?token=" + @@token
      json = JSON.parse(open(api_url).read)
      
      #Create array of Section objects
      @sections = []
      json["result"]["courses"].each { |c| @sections << Section.new(c["id"]) }
      
      #Set variables according to Course JSON data
      @id = json["result"]["id"]
      @name = json["result"]["name"]
      @path = json["result"]["path"]
      
      #Get reviews for the Course -- this has to be a separate query
      api_url_reviews = @@api_endpt + "coursehistories/" + 
                        self.id.to_s + "/reviews?token=" + @@token
      json_reviews = JSON.parse(open(api_url_reviews).read)
      @reviews = json_reviews["result"]["values"]
    else
      raise CourseError, "Invalid course code specified.  Use format [DEPT-###]."
    end
  end
  
  def average(metric)
    #Ensure that we know argument type
    metric = metric.to_s if metric.is_a? Symbol

    if metric.is_a? String
      #Loop vars
      total, n = 0, 0
      
      #For each section, check if ratings include metric arg
      #if so, add metric rating to total && increment counting variable
      self.reviews.each do |review|
        if review["ratings"].include? metric
          total = total + review["ratings"][metric].to_f
          n = n + 1
        else
          raise CourseError, "No ratings found for \"#{metric}\" in #{self.name}."
        end
      end
      
      #Return average score as a float
      (total / n)
    else
      raise CourseError, "Invalid metric format. Metric must be a string or symbol."
    end
  end
  
  def recent(metric)
    #Ensure that we know argument type
    metric = metric.to_s if metric.is_a? Symbol
    
    if metric.is_a? String
      #Get the most recent section
      section = self.sections[-1]
      
      #Iterate through all the section reviews, and if the section review id matches
      #the id of the most recent section, return that rating
      self.reviews.each do |review|
        if review["section"]["id"].to_s[0..4].to_i == section.id
          return review["ratings"][metric]
        end
      end
      
      #Else, metric hasn't been found
      raise CourseError, "No ratings found for #{metric} in #{section.semester}."
    else
      raise CourseError, "Invalid metric format. Metric must be a string or symbol."
    end
  end
end