require 'json'
require 'open-uri'

module PCR

	#Add some useful String methods
	class ::String
		#Checks if String is valid Penn course code format
		def isValidCourseCode?
			test = self.split('-')
			if test[0].length == 4 and test[1].length == 3
				true
			else
				false
			end
		end
	end

	#API class handles token and api url, so both are easily changed
	class API
		attr_accessor :token, :api_endpt
		def initialize()
			@token = File.open('token.dat', &:readline)
			@api_endpt = "http://api.penncoursereview.com/v1/"
		end
	end
	
	#CourseError serves as a more specific exception so we know where exactly exceptions are coming from.  SectionError and InstructorError should follow.
	class CourseError < StandardError
	end

	#Course object matches up with the coursehistory request of the pcr api.
	#A Course essentially is a signle curriculum and course code, and includes all Sections across time (semesters).
	class Course
		attr_accessor :course_code, :sections, :id, :name, :path, :reviews
		
		def initialize(args)
			#Set indifferent access for args hash
			args.default_proc = proc do |h, k|
			   case k
				 when String then sym = k.to_sym; h[sym] if h.key?(sym)
				 when Symbol then str = k.to_s; h[str] if h.key?(str)
			   end
			end
			
			#Initialization actions
			if args[:course_code].is_a? String and args[:course_code].isValidCourseCode?
				@course_code = args[:course_code]
				
				#Read JSON from the PCR API
				pcr = PCR::API.new()
				api_url = pcr.api_endpt + "coursehistories/" + self.course_code + "/?token=" + pcr.token
				json = JSON.parse(open(api_url).read)
				
				#Create array of Section objects, containing all Sections found in the API JSON for the Course
				@sections = []
				json["result"]["courses"].each do |c|
					@sections << Section.new(:aliases => c["aliases"], :id => c["id"], :name => c["name"], :path => c["path"], :semester => c["semester"])
				end
				
				#Set variables according to Course JSON data
				@id = json["result"]["id"]
				@name = json["result"]["name"]
				@path = json["result"]["path"]
				
				#Get reviews for the Course -- unfortunately this has to be a separate query
				api_url_reviews = pcr.api_endpt + "coursehistories/" + self.id.to_s + "/reviews?token=" + pcr.token
				json_reviews = JSON.parse(open(api_url_reviews).read)
				@reviews = json_reviews["result"]["values"]

			else
				raise CourseError, "Invalid course code specified.  Use format [DEPT-###]."
			end
		end
		
		def average(metric)
			#Ensure that we know argument type
			if metric.is_a? Symbol
				metric = metric.to_s
			end
			
			if metric.is_a? String
				#Loop vars
				total = 0
				n = 0
				
				#For each section, check if ratings include metric arg -- if so, add metric rating to total and increment counting variable
				self.reviews.each do |review|
					ratings = review["ratings"]
					if ratings.include? metric
						total = total + review["ratings"][metric].to_f
						n = n + 1
					else
						raise CourseError, "No ratings found for \"#{metric}\" in #{self.name}."
					end
				end
				
				#Return average score as a float
				return (total/n)
				
			else
				raise CourseError, "Invalid metric format. Metric must be a string or symbol."
			end
		end
		
		def recent(metric)
			#Ensure that we know argument type
			if metric.is_a? Symbol
				metric = metric.to_s
			end
			
			
			if metric.is_a? String
				#Get the most recent section
				section = self.sections[-1]
				
				#Iterate through all the section reviews, and if the section review id matches the id of the most recent section, return that rating
				self.reviews.each do |review|
					if review["section"]["id"].to_s[0..4].to_i == section.id
						return review["ratings"][metric]
					end
				end
				
				raise CourseError, "No ratings found for #{metric} in #{section.semester}."
				
			else
				raise CourseError, "Invalid metric format. Metric must be a string or symbol."
			end
		end
	end
	
	#Section is an individual class under the umbrella of a general Course
	class Section
		attr_accessor :aliases, :id, :name, :path, :semester, :description, :comments, :ratings, :instructor
		
		def initialize(args)
			#Set indifferent access for args
			args.default_proc = proc do |h, k|
			   case k
				 when String then sym = k.to_sym; h[sym] if h.key?(sym)
				 when Symbol then str = k.to_s; h[str] if h.key?(str)
			   end
			end
			
			pcr = PCR::API.new()
			@aliases = args[:aliases] if args[:aliases].is_a? Array
			@id = args[:id] if args[:id].is_a? Integer
			@name = args[:name] if args[:name].is_a? String
			@path = args[:path] if args[:path].is_a? String
			@semester = args[:semester] if args[:semester].is_a? String
			
			api_url = pcr.api_endpt + "courses/" + self.id.to_s + "?token=" + pcr.token
			json = JSON.parse(open(api_url).read)
			@description = json["result"]["description"]
			
			@comments = ""
			@ratings = {}
			@instructor = {}
		end
		
		def reviews()
			pcr = PCR::API.new()
			api_url = pcr.api_endpt + "courses/" + self.id.to_s + "/reviews?token=" + pcr.token
			json = JSON.parse(open(api_url).read)
			@comments = json["result"]["values"][0]["comments"]
			@ratings = json["result"]["values"][0]["ratings"]
			@instructor = json["result"]["values"][0]["instructor"]
			
			return {:comments => @comments, :ratings => @ratings}
		end
	end
end