require 'json'
require 'open-uri'
require 'time'
require 'csv'


#PCR class handles token and api url, so both are easily changed
class PCR
  def initialize(token, api_endpt = "http://api.penncoursereview.com/v1/")
    @@token = token
    @@api_endpt = api_endpt
  end
  
  def course(course_code)
    Course.new(course_code)
  end
  
  def section(*args)
    Section.new(*args)
  end
  
  def instructor(id, *args)
    Instructor.new(id, *args)
  end
end

# Load classes
Dir[File.dirname(__FILE__) + "/classes/*.rb"].each { |file| require file }