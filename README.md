# pcr-ruby: A Penn Course Review Ruby API Wrapper #

pcr-ruby is a simple, intuitive way to retrieve course data from the Penn Course Review API in Ruby.  With pcr-ruby and a valid API token (which you can request [here](https://docs.google.com/spreadsheet/viewform?hl=en_US&formkey=dGZOZkJDaVkxdmc5QURUejAteFdBZGc6MQ#gid=0)), your Ruby project has access to reviews, ratings, and other information for all Penn courses.

## Installation ##

pcr-ruby is a gem hosted on rubygems, so installation is as simple as:
```
gem install pcr-ruby
```

## How to use pcr-ruby #

*This section may change a lot as pcr-ruby is developed.  As such, this section may not be fully accurate, but I will try to keep the instructions as current as possible.*

pcr-ruby follows the structure of the PCR API, with a few name changes to make object identities and roles clearer in your code.  (Before using pcr-ruby, you should most definitely read the PCR API documentation, the link to which you should recieve upon being granted your API token.)

The PCR API essentially consists of four types of objects: 'Courses', 'Sections', 'Instructors', and 'Course Histories'.  pcr-ruby aims to provide intuitive access to the data contained in these four object types while abstracting you and your user from background processing and unnecessary data.  To that end, pcr-ruby (thus far) consists of the same four types of objects: 'Course Histories', 'Courses', 'Sections', and 'Instructors' (coming soon).

### CourseHistories in pcr-ruby ###
Course Histories represent a course through time, and contain Course objects that represent the course offering in each semester.

To create a Course History (the first step in getting PCR data):
```ruby
require 'pcr-ruby'
pcr = PCR.new(API_TOKEN)
course_history = pcr.coursehistory(COURSE_CODE)
```

All other attributes will auto-populate based on data from the PCR API.

Course Histories have the following attributes:
* **course_code** -- the course code entered by the user at initialization (String)
* **courses** -- an array of Courses associated with the Course History (Array)
* **id** -- the Course History's PCR API ID (String)
* **path** -- the Course History's PCR API URL path (String)
* **retrieved** -- the date the Course History was retreived (String)
* **valid** -- true/false whether or not the query was valid (String)
* **version** -- version of the PCR API hit (String)

The most useful way to think about a Course History is as a collection of Course objects.

Course Histories have the following instance methods:
*	**average(metric)** -- returns the average value, across all Courses, of "metric" as a Float.  "Metric" must be a recognized rating in the PCR API.  (Currently the names of these ratings are not intuitive, so I may provide plain-English access to rating names in the future.)
*	**recent(metric)** -- returns the most recent value of "metric" as a Float. (If there are multiple Sections offered in the most recent semester, the average across those Sections is returned.)  "Metric" must be a recognized rating in the PCR API.  (Currently the names of these ratings are not intuitive, so I may provide plain-English access to rating names in the future.)

### 'Courses' in pcr-ruby ###

Courses in the PCR API represent a collection of Sections of a course code during a given semester, and are treated similarly in pcr-ruby.

Courses are accessed from within their "parent" Course History:
```ruby
require 'pcr-ruby'
pcr = PCR.new(API_TOKEN)
course_history = pcr.coursehistory(course_code)
courses = course_history.courses
earliest_course = courses.first
most_recent_course = courses.last
```

pcr-ruby's Course objects have the following instance variables:
* **aliases** -- an array of crosslistings (Array)
* **credits** -- the number of credits awarded for the course (String)
* **description** -- the PCR course description (String)
* **history** -- the PCR API path to the course's history (String)
* **id** -- the PCR API ID of the course (String)
* **name** -- the plain-English name of the course, taken from the most recent Semester (String)
* **path** -- the PCR API URL path of the course (String)
* **reviews** -- a hash that usually contains one key, the path to the course's reviews (String) 
* **sections** -- an array of Sections associated with the course (Array)
* **semester** -- the semester in which the course was offered (String)
* **retrieved** -- the date/time the course was retrieved (String)
* **valid** -- true/false if valid/invalid request (String)
* **version** -- PCR API version (String)

The most useful way to think about Courses is as a collection of Section objects.

### 'Sections' in pcr-ruby ###

In pcr-ruby, Sections are single offerings of a Course.  Each Section is associated with a certain Course -- think of a Section as the individual classes under the umbrella of the Course.  Sections in the PCR API are treated similarly.

To retrieve a Section:
```ruby
require 'pcr-ruby'
pcr = PCR.new(API_TOKEN)
course_history = pcr.coursehistory(course_code)
recent_sections = course_history.courses.last.sections
single_recent_section = recent_sections.first
```

Sections have the following instance variables:
* **aliases** -- crosslistings of the Section (Array)
* **course** -- a hash containing info of the parent course (Hash)
* **group** -- 
* **id** -- the PCR API ID of the section (String)
* **instructors** -- a hash of info on each of the section's instructors (Hash)
* **meetingtimes** -- an array of hashes that contain info on each of the meeting times of the section (Array)
* **name** -- the plain-English name of the section (String)
* **path** -- the PCR API URL path of the section (String)
* **reviews** -- an array of hashes which each contain the review data for the section (usually only one review hash) (Array)
* **sectionnum** -- the number of the section (e.g. "001") (String)
* **retrieved** -- date/time retrieved (String)
* **valid** -- true/false if query valid/invalid (String)
* **version** -- PCR API version (String)

### 'Instructors' in pcr-ruby ###

(New version of instructors coming soon)

## pcr-ruby Usage Examples ##

Here are some (hopefully very simple and intuitive) usage examples for pcr-ruby:

### Get average course quality rating ###
Let's say we want to find the average course quality rating for Introduction to International Relations, PSCI-150:

```ruby
require 'pcr-ruby'
course_code = "PSCI-150"
pcr = PCR.new(API_TOKEN)
psci150 = pcr.coursehistory(course_code)
puts psci150.average("rCourseQuality") #=> 3.041
```

Or, even more briefly:

```ruby
require 'pcr-ruby'
pcr = PCR.new(API_TOKEN)
puts pcr.coursehistory("PSCI-150").average("rCourseQuality")
#=> 3.041
```

### Get most recent course difficulty rating ###
Finding the most recent section's course difficulty rating is just as easy:

```ruby
require 'pcr-ruby'
course_code = "PSCI-150"
pcr = PCR.new(API_TOKEN)
psci150 = pcr.coursehistory(course_code)
puts psci150.average("rDifficulty") #=> 2.59
```

## TODO ##
* Implement refactored Instructor object
* Implement stricter checks on course code arguments
*	Implement search by professor last/first name rather than by ID.  ID is unintuitive.  Will probably need to see if I can make a lookup method, or simply pull down a database of all instructors and do a search on that database.