#main.rb - executable code using pcr api

require './pcr.rb'

course_code = "ASTR-001"

puts "Downloading course data for #{course_code}..."
course = PCR::Course.new(:course_code => course_code)
puts "Getting most recent instructor quality score for #{course_code + " - " + course.name}..."
puts "Most recent instructor quality = " + course.recent("rInstructorQuality").to_s