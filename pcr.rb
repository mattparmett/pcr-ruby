require 'json'
require 'open-uri'

# class Hash
	# def indifferent_access()
		# self.each do |h, k|
		   # case k
			 # when String then sym = k.to_sym; h[sym] if h.key?(sym)
			 # when Symbol then str = k.to_s; h[str] if h.key?(str)
		   # end
		# end
	# end
# end

module PCR

	class API
		attr_accessor :token, :api_endpt
		
		def initialize()
			@token = File.open('token.dat', &:readline)
			@api_endpt = "http://api.penncoursereview.com/v1/"
		end
		
	end
	
	class CourseError < StandardError
	end

	#Course object matches up with the coursehistory request of the pcr api.
	#Course will have sections, represented by an array of Section objects
	class Course
		attr_accessor :course_code, :sections, :id, :name, :path, :reviews
		
		def initialize(args)
			#Set indifferent access for args
			args.default_proc = proc do |h, k|
			   case k
				 when String then sym = k.to_sym; h[sym] if h.key?(sym)
				 when Symbol then str = k.to_s; h[str] if h.key?(str)
			   end
			end
			
			if args[:course_code].is_a? String #need to split string at "-" to make sure first part has 4 letter code and second has 3 numbers
				@course_code = args[:course_code]
				pcr = PCR::API.new()
				api_url = pcr.api_endpt + "coursehistories/" + self.course_code + "/?token=" + pcr.token
				json = JSON.parse(open(api_url).read)
				@sections = []
				json["result"]["courses"].each do |c|
					@sections << Section.new(:aliases => c["aliases"], :id => c["id"], :name => c["name"], :path => c["path"], :semester => c["semester"])
				end
				@id = json["result"]["id"]
				@name = json["result"]["name"]
				@path = json["result"]["path"]
				api_url_reviews = pcr.api_endpt + "coursehistories/" + self.id.to_s + "/reviews?token=" + pcr.token
				json_reviews = JSON.parse(open(api_url_reviews).read)
				@reviews = json_reviews["result"]["values"]
			else
				raise CourseError, "Invalid course code specified.  Use format [CCCC-###]."
			end
		end
		
		def average(metric)
			if metric.is_a? Symbol
				metric = metric.to_s
			end
			if metric.is_a? String
				total = 0
				n = 0
				self.reviews.each do |review|
					ratings = review["ratings"]
					if ratings.include? metric
						total = total + review["ratings"][metric].to_f
						n = n + 1
					else
						raise CourseError, "No ratings found for \"#{metric}\" in #{self.name}."
					end
				end
				return (total/n)
			else
				raise CourseError, "Invalid metric format. Metric must be a string or symbol."
			end
		end
		
		def recent(metric)
			if metric.is_a? Symbol
				metric = metric.to_s
			end
			if metric.is_a? String
				section = self.sections[0]
				ratings = section.reviews[:ratings]
				if ratings.include? metric
					return ratings[metric].to_f
				else
					raise CourseError, "No ratings found for #{metric} in #{section.semester}."
				end
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