class Section < PCR
  attr_accessor :aliases, :course, :group, :id, :instructors, 
                :meetingtimes, :name, :path, :reviews, 
                :sectionnum, :retrieved, :valid, :version
  
  def initialize(path, api_endpt, token)
    @path = path
    @api_endpt = api_endpt
    @token = token
        
    # Hit api
    api_url = makeURL(self.path)
    json = JSON.parse(open(api_url).read)
    
    # Get reviews
    # Usually one, but may be > 1
    @reviews = []
    reviews_url = makeURL(json['result']['reviews']['path'])
    reviews_json = JSON.parse(open(reviews_url).read)
    reviews_json['result']['values'].each do |review|
      @reviews << Review.new(review)
    end
    
    # Assign attrs
    attrs = %w(aliases course group id instructors meetingtimes name 
               sectionnum retrieved valid version)
    attrs.each do |attr|
      if json['result'][attr]
        self.instance_variable_set("@#{attr}", json['result'][attr])
      else
        self.instance_variable_set("@#{attr}", json[attr])
      end
    end
  end

end