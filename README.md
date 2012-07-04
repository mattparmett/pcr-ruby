# pcr-ruby: A Penn Course Review Ruby API Wrapper #

pcr-ruby is a simple, intuitive way to retrieve course data from the Penn Course Review API in Ruby.  With pcr-ruby and a valid API token (which you can request [here](https://docs.google.com/spreadsheet/viewform?hl=en_US&formkey=dGZOZkJDaVkxdmc5QURUejAteFdBZGc6MQ#gid=0)), your Ruby project has access to reviews, ratings, and other information for all Penn courses.

## How to use pcr-ruby #

*This section will change a lot as pcr-ruby is developed.  As such, this section may not be fully accurate, but I will try to keep the instructions as current as possible.*

pcr-ruby follows the structure of the PCR API, with a few name changes to make object identities and roles clearer in your code.  (Before using pcr-ruby, you should most definitely read the PCR API documentation, the link to which you should recieve upon being granted your API token.)

The PCR API essentially consists of four types of objects: 'Courses', 'Sections', 'Instructors', and 'Course Histories'.  pcr-ruby aims to provide intuitive access to the data contained in these four object types while abstracting you and your user from background processing and unnecessary data.  To that end, pcr-ruby (thus far) consists of two types of objects: 'Courses' and 'Sections' ('Instructors' coming soon).

### 'Courses' in pcr-ruby ###

Course objects in the PCR API are essentially a group of that Course's Sections which were offered in a certain semester.  Courses in pcr-ruby are different, and match up most directly with 'Course History' objects of the PCR API.  It is my belief that when students think of a "course," they think of the entire history of the course and *not* the course offering for a specific semester.  Therefore, pcr-ruby does not associate Courses with specific semesters -- rather, Courses exist across time and represent a single curriculum and course code.

To create a Course:
`course = PCR::Course.new(:course_code => "DEPT-###")`
All other instance variables will auto-populate based on data from the PCR API.

pcr-ruby's Course objects have the following instance variables:
*	**course_code** -- a string in the format "DEPT-###", where "DEPT" is the four-letter department code and "###" is the three-digit course code.
*	**sections** -- an array of Section objects for the Course across all time.  Useful for calculating average ratings and other cumulative statistics.
*	**id** -- the Course's PCR API id. (Integer)
*	**name** -- the Course's plain-English name.  (String)
*	**path** -- the PCR API sub-path leading to the Course (or, more accurately, the Course History).  For example, "/coursehistories/1794/".  Or, more generally: "/coursehistories/[id]/".  (String)
*	**reviews** -- an array of Hashes that contain review data for each of the Course's sections.

Courses have the following instance methods:
*	**average(metric)** -- returns the average value, across all Sections, of "metric" as a Float.  "Metric" must be a recognized rating in the PCR API.  (Currently the names of these ratings are not intuitive, so I may provide plain-English access to rating names in the future.)
*	**recent(metric)** -- returns the most recent value of "metric" as a Float.  "Metric" must be a recognized rating in the PCR API.  (Currently the names of these ratings are not intuitive, so I may provide plain-English access to rating names in the future.)

### 'Sections' in pcr-ruby ###

In pcr-ruby, Sections are single offerings of a Course.  Each Section is associated with a certain Instructor and semester -- think of a Section as the individual classes under the umbrella of the Course.  Sections in the PCR API are treated similarly.

To create a Section:
`section = PCR::Section.new(:instance_variable => value)`
Possible instance variables available for setting in the Section initialize method are: aliases, id, name, path, semester.

Sections have the following instance variables:
*	**aliases** -- an array of the Section's course listings.  Most of the time, a Section will only have one listing (the course code followed by a section code, like "-001"), but Sections that are cross-listed between departments may have multiple listings.
*	**id** -- the Section's PCR API id.  (Integer)
*	**name** -- the plain-English name of the class.  (String)
*	**path** -- the PCR API sub-path that leads to the Section.  Similar in format to Course.path.  (String)
*	**semester** -- the semester code for the semester in which the Section was offered.  For example: "2011A".  Semester codes are in the format "####X", where "####" represents a year and "X" represents a semester (A for Spring, B for Summer, C for Fall).  (String)
*	**description** -- a string containing the class description, which is written by the Section's Instructor and details the scope and characteristics of the class.
*	**comments** -- a string containing PCR's comments about the Section.  The comments are the most major part of the written review, and are sourced from student exit surveys.
*	**ratings** -- a Hash of metrics and the ratings of the Section for each metric.
*	**instructor** (to be developed) -- the Instructor object for the Section's professor.

Sections have the following instance methods:
*	**reviews()** -- retrieves the Section's review data from PCR.  Returns a Hash in the format {"comments" => @comments, "ratings" => @ratings}.

## pcr-ruby Usage Examples ##

Here are some (hopefully very simple and intuitive) usage examples for pcr-ruby:

### Get average course quality rating ###
Let's say we want to find the average course quality rating for Introduction to International Relations, PSCI-150:

`require 'pcr.rb'
course_code = "PSCI-150"
course = PCR::Course.new(:course_code => course_code)
puts course.average("rCourseQuality") #=> 3.041`

Or, even more briefly:

`require 'pcr.rb'
puts PCR::Course.new(:course_code => "PSCI-150").average("rCourseQuality") #=> 3.041`

### Get most recent course difficulty rating ###
Finding the most recent section's course difficulty rating is just as easy:

`require 'pcr.rb'
course = PCR::Course.new(:course_code => "PSCI-150")
puts course.recent("rDifficulty") #=> 2.55`