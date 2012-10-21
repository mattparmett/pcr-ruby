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