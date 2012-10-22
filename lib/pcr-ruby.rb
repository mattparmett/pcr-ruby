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
  
  def section(id, hit_api = true)
    Section.new(id, hit_api)
  end
  
  def instructor(id)
    Instructor.new(id)
  end
end

# Load classes
Dir[File.dirname(__FILE__) + "/classes/*.rb"].each { |file| require file }