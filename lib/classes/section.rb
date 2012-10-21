#Section is an individual class under the umbrella of a general Course
class Section < PCR
  attr_accessor :aliases, :id, :name, :path, :semester, :description, :comments, :ratings, :instructor
  
  def initialize(id, args = {})
    #Set indifferent access for args
    if args.length > 0
      args.default_proc = proc do |h, k|
         case k
         when String then sym = k.to_sym; h[sym] if h.key?(sym)
         when Symbol then str = k.to_s; h[str] if h.key?(str)
         end
      end
    end
    
    @aliases = args[:aliases] if args[:aliases].is_a? Array
    @id = id if id.is_a? Integer
    @name = args[:name] if args[:name].is_a? String
    @path = args[:path] if args[:path].is_a? String
    @semester = args[:semester] if args[:semester].is_a? String
    @comments = ""
    @ratings = {}
    @instructor = {}
    
    unless args[:hit_api] == false
      unless args[:get_reviews] == false
        self.hit_api(:get_reviews => true)
      end
    end
  end
  
  def hit_api(args)
    data = ["aliases", "name", "path", "semester", "description"]
    api_url = @@api_endpt + "courses/" + self.id.to_s + "?token=" + @@token
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
    api_url = @@api_endpt + "courses/" + self.id.to_s + "/reviews?token=" + @@token
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