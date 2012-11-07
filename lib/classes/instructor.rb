#Instructor is a professor.  Instructors are not tied to a course or section, but will have to be referenced from Sections.
class Instructor < PCR
  attr_accessor :id, :name, :path, :sections, :reviews
  
  def initialize(id)    
    #Assign args
    if id.is_a? String
      @id = id
    else
      raise InstructorError("Invalid Instructor ID specified.")
    end
    
    #Hit PCR API to get missing info based on id
    self.getInfo
    self.getReviews
  end
  
  #Hit the PCR API to get all missing info
  def getInfo
    api_url = @@api_endpt + "instructors/" + self.id + "?token=" + @@token
    json = JSON.parse(open(api_url).read)
    @name = json["result"]["name"].downcase.titlecase unless @name
    @path = json["result"]["path"] unless @path
    @sections = json["result"]["reviews"]["values"] unless @sections #Mislabeled reviews in PCR API
  end
  
  #Separate method for getting review data
  def getReviews
    api_url = @@api_endpt + "instructors/" + self.id + "/reviews?token=" + @@token
    json = JSON.parse(open(api_url).read)
    @reviews = json["result"]["values"] #array
  end
  
  #Get average value of a certain rating for Instructor
  def average(metric)
    #Ensure that we know argument type
    metric = metric.to_s if metric.is_a? Symbol
    
    if metric.is_a? String
      #Loop vars
      total, n = 0, 0
      
      #For each section, check if ratings include metric arg
      #if so, add metric rating to total and increment counting variable
      self.getReviews
      self.reviews.each do |review|
        if review["ratings"].include? metric
          total = total + review["ratings"][metric].to_f
          n = n + 1
        else
          raise CourseError, "No ratings found for \"#{metric}\" for #{self.name}."
        end
      end
      
      #Return average score as a float
      (total / n)
    else
      raise CourseError, "Invalid metric format. Metric must be a string or symbol."
    end
  end

  #Get most recent value of a certain rating for Instructor
  def recent(metric)
    #Ensure that we know argument type
    metric = metric.to_s if metric.is_a? Symbol
    
    if metric.is_a? String
      #Iterate through reviews and create Section for each section reviewed, presented in an array
      sections = []
      section_ids = []
      self.getReviews
      self.reviews.each do |review|
        if section_ids.index(review["section"]["id"].to_i).nil?
          s = PCR::Section.new(review["section"]["id"].to_i, false)
          sections << s
          section_ids << s.id
        end
      end
      
      #Get only most recent Section(s) in the array
      sections.reverse! #Newest first
      targets = []
      sections.each do |s|
        s.hit_api
        if sections.index(s) == 0
          targets << s
        elsif s.semester == sections[0].semester && s.id != sections[0].id
          targets << s
        else
          break
        end
      end
      
      #Calculate recent rating
      total, num = 0, 0
      targets.each do |section|
        #Make sure we get the rating for the right Instructor
        section.ratings.each do |rating|
          if rating.key?(self.id)
            if rating[self.id][metric].nil?
              raise InstructorError, "No ratings found for #{metric} for #{self.name}."
            else
              total = total + rating[self.id][metric].to_f
              num += 1
            end
          end
        end
      end

      # Return recent rating
      (total / num)
    else
      raise CourseError, "Invalid metric format. Metric must be a string or symbol."
    end
  end
end