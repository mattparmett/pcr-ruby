#Section is an individual class under the umbrella of a general Course
class Section < PCR
  attr_accessor :aliases, :id, :name, :path, :semester, :description, :comments, :ratings, :instructors, :reviews
  
  def initialize(id, hit_api = true)
    # Set instance vars
    @id = id
    
    # Hit api to fill additional info
    self.hit_api unless hit_api == false
  end
  
  def hit_api
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
    
    # Get review data
    self.get_reviews
  end
  
  def get_reviews
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
    @reviews = {"comments" => @comments, "ratings" => @ratings}
  end
  
end