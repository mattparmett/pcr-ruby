require 'json'
require 'open-uri'
require 'time'
require 'csv'

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
		
		#Methods to convert strings to titlecase.
		#Thanks https://github.com/samsouder/titlecase
		def titlecase
			small_words = %w(a an and as at but by en for if in of on or the to v v. via vs vs.)

			x = split(" ").map do |word|
			  # note: word could contain non-word characters!
			  # downcase all small_words, capitalize the rest
			  small_words.include?(word.gsub(/\W/, "").downcase) ? word.downcase! : word.smart_capitalize!
			  word
			end
			# capitalize first and last words
			x.first.smart_capitalize!
			x.last.smart_capitalize!
			# small words after colons are capitalized
			x.join(" ").gsub(/:\s?(\W*#{small_words.join("|")}\W*)\s/) { ": #{$1.smart_capitalize} " }
		end

		def smart_capitalize
			# ignore any leading crazy characters and capitalize the first real character
			if self =~ /^['"\(\[']*([a-z])/
			  i = index($1)
			  x = self[i,self.length]
			  # word with capitals and periods mid-word are left alone
			  self[i,1] = self[i,1].upcase unless x =~ /[A-Z]/ or x =~ /\.\w+/
			end
			self
		end

		def smart_capitalize!
			replace(smart_capitalize)
		end
		
		#Method to compare semesters. Returns true if self is later, false if self is before, 0 if same
		#s should be a string like "2009A"
		def compareSemester(s)
			year = self[0..3]
			season = self[4]
			compYear = s[0..3]
			compSeason = s[4]
			
			if year.to_i > compYear.to_i #Later year
				return true
			elsif year.to_i < compYear.to_i #Earlier year
				return false
			elsif year.to_i == compYear.to_i #Same year, so test season
				if season > compSeason #Season is later
					return true
				elsif season = compSeason #Exact same time
					return 0
				elsif season < compSeason #compSeason is later
					return false
				end
			end
		end
	end
	
	#Add useful array methods
	class Array
		def binary_search(target)
			self.search_iter(0, self.length-1, target)
		end

		def search_iter(lower, upper, target)
			return -1 if lower > upper
			mid = (lower+upper)/2
			if (self[mid] == target)
				mid
			elsif (target < self[mid])
				self.search_iter(lower, mid-1, target)
			else
				self.search_iter(mid+1, upper, target)
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
	
	#These errors serve as more specific exceptions so we know where exactly errors are coming from.
	class CourseError < StandardError
	end
	
	class InstructorError < StandardError
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
					@sections << Section.new(:aliases => c["aliases"], :id => c["id"], :name => c["name"], :path => c["path"], :semester => c["semester"], :hit_api => true)
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
			@comments = ""
			@ratings = {}
			@instructor = {}
			
			if args[:hit_api]
				if args[:get_reviews]
					self.hit_api(:get_reviews => true)
				else
					self.hit_api(:get_reviews => false)
				end
			end
		end
		
		def hit_api(args)
			data = ["aliases", "name", "path", "semester", "description"]
			pcr = PCR::API.new()
			api_url = pcr.api_endpt + "courses/" + self.id.to_s + "?token=" + pcr.token
			json = JSON.parse(open(api_url).read)
			
			data.each do |d|
				case d
				when "aliases"
					self.instance_variable_set("@#{d}", json["result"]["aliases"])
				when "name"
					self.instance_variable_set("@#{d}", json["result"]["name"])
				when "path"
					self.instance_variable_set("@#{d}", json["result"]["path"])
				when "semester"
					self.instance_variable_set("@#{d}", json["result"]["semester"])
				when "description"
					self.instance_variable_set("@#{d}", json["result"]["description"])
				end
			end
			
			if args[:get_reviews]
				self.reviews()
			end
		end
		
		def reviews()
			pcr = PCR::API.new()
			api_url = pcr.api_endpt + "courses/" + self.id.to_s + "/reviews?token=" + pcr.token
			json = JSON.parse(open(api_url).read)
			@comments = []
			@ratings = []
			@instructors = []
			json["result"]["values"].each do |a|
				@comments << {a["instructor"]["id"] => a["comments"]}
				@ratings << {a["instructor"]["id"] => a["ratings"]}
				@instructors << a["instructor"]
			end
			# @comments = json["result"]["values"][0]["comments"]
			# @ratings = json["result"]["values"][0]["ratings"]
			# @instructor = json["result"]["values"][0]["instructor"]
			
			return {:comments => @comments, :ratings => @ratings}
		end
		
		def after(s)
			if s.is_a? Section
				self.semester.compareSemester(s.semester)
			elsif s.is_a? String
				self.semester.compareSemester(s)
			end
		end
	end
	
	#Instructor is a professor.  Instructors are not tied to a course or section, but will have to be referenced from Sections.
	class Instructor
		attr_accessor :id, :name, :path, :sections, :reviews
		
		def initialize(id, args)
			#Set indifferent access for args
			args.default_proc = proc do |h, k|
			   case k
				 when String then sym = k.to_sym; h[sym] if h.key?(sym)
				 when Symbol then str = k.to_s; h[str] if h.key?(str)
			   end
			end	
			
			#Assign args. ID is necessary because that's how we look up Instructors in the PCR API.
			if id.is_a? String
				@id = id
			else
				raise InstructorError("Invalid Instructor ID specified.")
			end

			@name = args[:name].downcase.titlecase if args[:name].is_a? String
			@path = args[:path] if args[:path].is_a? String
			@sections = args[:sections] if args[:sections].is_a? Hash
			
			#Hit PCR API to get missing info, if requested
			if args[:hit_api] == true
				self.getInfo
				self.getReviews
			end
		end
		
		#Hit the PCR API to get all missing info
		#Separate method in case we want to conduct it separately from a class init
		def getInfo
			pcr = PCR::API.new()
			api_url = pcr.api_endpt + "instructors/" + self.id + "?token=" + pcr.token
			json = JSON.parse(open(api_url).read)
			
			@name = json["result"]["name"].downcase.titlecase unless @name
			@path = json["result"]["path"] unless @path
			@sections = json["result"]["reviews"]["values"] unless @sections #Mislabeled reviews in PCR API
		end
		
		#Separate method for getting review data in case we don't want to make an extra API hit each init
		def getReviews
			if not self.reviews #make sure we don't already have reviews
				pcr = PCR::API.new()
				api_url = pcr.api_endpt + "instructors/" + self.id + "/reviews?token=" + pcr.token
				json = JSON.parse(open(api_url).read)
				
				@reviews = json["result"]["values"] #gets array
			end
		end
		
		#Get average value of a certain rating for Instructor
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
				self.getReviews
				self.reviews.each do |review|
					ratings = review["ratings"]
					if ratings.include? metric
						total = total + review["ratings"][metric].to_f
						n = n + 1
					else
						raise CourseError, "No ratings found for \"#{metric}\" for #{self.name}."
					end
				end
				
				#Return average score as a float
				return (total/n)
				
			else
				raise CourseError, "Invalid metric format. Metric must be a string or symbol."
			end
		end

		#Get most recent value of a certain rating for Instructor
		def recent(metric)
			#Ensure that we know argument type
			if metric.is_a? Symbol
				metric = metric.to_s
			end
			
			if metric.is_a? String
				#Iterate through reviews and create Section for each section reviewed, presented in an array
				sections = []
				section_ids = []
				self.getReviews
				self.reviews.each do |review|
					if section_ids.index(review["section"]["id"].to_i).nil?
						s = PCR::Section.new(:id => review["section"]["id"].to_i, :hit_api => false)
						sections << s
						section_ids << s.id
					end
				end
				
				#Get only most recent Section(s) in the array
				sections.reverse! #Newest first
				targets = []
				sections.each do |s|
					s.hit_api(:get_reviews => true)
					if sections.index(s) == 0
						targets << s
					elsif s.semester == sections[0].semester and s.id != sections[0].id
						targets << s
					else
						break
					end
				end
				
				#Calculate recent rating
				total = 0
				num = 0
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

				return total / num
				
			else
				raise CourseError, "Invalid metric format. Metric must be a string or symbol."
			end
		end
	end

end #module
	
#Some instance methods to handle instructor searching
def downloadInstructors(instructors_db)
	pcr = PCR::API.new()
	api_url = pcr.api_endpt + "instructors/" + "?token=" + pcr.token
	#puts "Downloading instructors json..."
	json = JSON.parse(open(api_url).read)
	
	#Parse api data, writing to file
	begin
		File.open(instructors_db, 'w') do |f|
			instructor_hashes = json["result"]["values"]
			file_lines = []
			#puts "Constructing instructor file_lines"
			instructor_hashes.each do |instructor|
				n = instructor["name"].split(" ")
				file_lines << ["#{n[2]} #{n[1]} #{n[0]}",instructor["id"]] if n.length == 3 #if instructor has middle name
				file_lines << ["#{n[1]} #{n[0]}",instructor["id"]] if n.length == 2 #if instructor does not have middle name
			end
			
			#Sort lines alphabetically
			#puts "sorting file lines alphabetically..."
			file_lines.sort! { |a,b| a[0] <=> b[0] }

			#Write lines to csv file
			#puts "writing file lines to csv file..."
			file_lines.each { |line|	f.write("#{line[0]},#{line[1]}\n") }
		end
	rescue IOError => e
	  puts "Could not write to instructors file"
	rescue Errno::ENOENT => e
	  puts "Could not open instructors file"
	end
end

def instructorSearch(args)
	#Set indifferent access for args
	args.default_proc = proc do |h, k|
	   case k
		 when String then sym = k.to_sym; h[sym] if h.key?(sym)
		 when Symbol then str = k.to_s; h[str] if h.key?(str)
	   end
	end
	
	#Set args
	first_name = args[:first_name]
	middle_initial = args[:middle_initial]
	last_name = args[:last_name]
	
	#Check if we've downloaded instructors in last week
	begin
		last_dl_time = Time.local(File.mtime("instructors.txt").tv_sec).tv_sec
		#puts last_dl_time
	rescue Errno::ENOENT => e
	  downloadInstructors("instructors.txt") #instructors file doesn't exist, so download
	else
		current_time = Time.local(Time.now().tv_sec).tv_sec
		#puts current_time
		if current_time - last_dl_time <= 604800 #1 week in seconds
			downloadInstructors("instructors.txt")
		end
	end
	
	#Check if instructors file exists
	# begin
		# f = File.open("instructors.txt", "rb")
	# rescue Errno::ENOENT => e
		# downloadInstructors("instructors.txt")
	# end
	
	#Search for instructor name in instructors file and get corresponding ids, in an array
	#puts "searching instructors file..."
	results = []
	CSV.foreach("instructors.txt") do |line|
		results << {line[0] => line[1]}	if line[0].include? last_name.upcase
	end
	
	return results
end