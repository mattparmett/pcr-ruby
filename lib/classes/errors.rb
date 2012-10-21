#These errors serve as more specific exceptions so we know where exactly errors are coming from.
class CourseError < StandardError
end

class InstructorError < StandardError
end
