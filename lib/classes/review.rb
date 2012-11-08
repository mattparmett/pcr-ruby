#review_new.rb

class Review
  #attr_accessor
  
  def initialize(review_hash)
    # Assign ratings
    ratings = review_hash['ratings']
    ratings.each do |name, val|
      self.instance_variable_set("@#{name}", val)
      self.class.send(:attr_accessor, name)
      #self.class_eval("def #{name};@#{name};end")
    end
  end

end