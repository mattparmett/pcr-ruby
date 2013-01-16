require 'json'
require 'open-uri'
require 'classes/course'
require 'classes/errors'
require 'classes/section'
require 'classes/coursehistory'
require 'classes/review'
require 'classes/string'

#PCR class handles token and api url, so both are easily changed
module PCR
  class Client
    def initialize(token, api_endpt = "http://api.penncoursereview.com/v1/")
      @token = token
      @api_endpt = api_endpt
    end
  
    def get_json(path)
      JSON.parse(open("#{@api_endpt + path}?token=#{@token}"))
    end

    def coursehistory(course_code)
      CourseHistory.new(course_code, self.api_endpt, self.token)
    end

    def instructor(id)
      raise NotImplementedError.new("Instructors have not yet been implemented.")
    end

    def dept(code)
      raise NotImplementedError.new("Departments have not yet been implemented.")
    end
  end
end
