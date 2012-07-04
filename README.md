# pcr-ruby: A Penn Course Review Ruby API Wrapper #

pcr-ruby is a simple, intuitive way to retrieve course data from the Penn Course Review API in Ruby.  With pcr-ruby and a valid API token (which you can request [here](https://docs.google.com/spreadsheet/viewform?hl=en_US&formkey=dGZOZkJDaVkxdmc5QURUejAteFdBZGc6MQ#gid=0)), your Ruby project has access to reviews, ratings, and other information for all Penn courses.

## How to use pcr-ruby #

*This section will change a lot as pcr-ruby is developed.  As such, this section may not be fully accurate, but I will try to keep the instructions as current as possible.*

pcr-ruby follows the structure of the PCR API, with a few name changes to make object identities and roles clearer in your code.  (Before using pcr-ruby, you should most definitely read the PCR API documentation, the link to which you should recieve upon being granted your API token.)

The PCR API essentially consists of four types of objects: 'Courses', 'Sections', 'Instructors', and 'Course Histories'.  pcr-ruby aims to provide intuitive access to the data contained in these four object types while abstracting you and your user from background processing and unnecessary data.  To that end, pcr-ruby (thus far) consists of two types of objects: 'Courses' and 'Sections' ('Instructors' coming soon).

### 'Courses' in pcr-ruby ###

Course objects in the PCR API are essentially a group of that Course's Sections that were offered in a certain semester.  Courses in pcr-ruby are different, and match up most directly with 'Course History' objects of the PCR API.  It is my belief that when students think of a "course," they think of the entire history of the course and *not* the course offering for a specific semester.  Therefore, pcr-ruby does not associate Courses with specific semesters -- rather, Courses exist across time and represent a single curriculum and course code.

pcr-ruby's Course objects have the following instance variables:
*course_code -- a string in the format "DEPT-###", where "DEPT" is the four-letter department code and "###" is the three-digit course code.
*sections -- an array of Section objects for the Course across all time.  Useful for calculating average ratings and other cumulative statistics.
*id -- the Course's PCR API id. (Integer)
*name -- the Course's plain-English name.  (String)
*path -- the PCR API sub-path leading to the Course (or, more accurately, the Course History).  For example, "/coursehistories/1794/".  Or, more generally: "/coursehistories/[id]/".  (String)
*reviews -- an array of Hashes that contain review data.

