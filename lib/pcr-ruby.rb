require 'json'
require 'open-uri'

#PCR class handles token and api url, so both are easily changed
class PCR
  attr_accessor :token, :api_endpt
  
  def initialize(token, api_endpt = "http://api.penncoursereview.com/v1/")
    @token = token
    @api_endpt = api_endpt
  end
  
  def coursehistory(course_code)
    CourseHistory.new(course_code, self.api_endpt, self.token)
  end
  
  # def instructor(id)
    # Instructor.new(id)
  # end
  
  def makeURL(path)
    "#{self.api_endpt + path}?token=#{self.token}"
  end
  
end

# Load classes
Dir[File.dirname(__FILE__) + "/classes/*.rb"].each { |file| require file }