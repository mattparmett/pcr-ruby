class Course < PCR
  attr_accessor :aliases, :credits, :description, :history, :id, 
                :name, :path, :reviews, :sections, :semester, 
                :retrieved, :valid, :version
  
  def initialize(path, semester, api_endpt, token)
    @path, @semester = path, semester
    @api_endpt, @token = api_endpt, token
    
    # Hit api
    api_url = makeURL(self.path)
    json = JSON.parse(open(api_url).read)
    
    # List of sections
    section_list = json['result']['sections']['values']
    @sections = []
    section_list.each do |section|
      @sections << Section.new(section['path'], @api_endpt, @token)
    end
    
    # Assign attrs
    attrs = %w(aliases credits description history id name reviews 
               retrieved valid version)
    attrs.each do |attr|
      if json['result'][attr]
        self.instance_variable_set("@#{attr}", json['result'][attr])
      else
        self.instance_variable_set("@#{attr}", json[attr])
      end
    end
  end
  
  def compareSemester(other)
    year = self.semester[0..3]
    season = self.semester[4]
    compYear = other.semester[0..3]
    compSeason = other.semester[4]
    
    if year.to_i > compYear.to_i #Later year
      return 1
    elsif year.to_i < compYear.to_i #Earlier year
      return -1
    elsif year.to_i == compYear.to_i #Same year, so test season
      if season > compSeason #Season is later
        return 1
      elsif season = compSeason #Exact same time
        return 0
      elsif season < compSeason #compSeason is later
        return -1
      end
    end
  end

end