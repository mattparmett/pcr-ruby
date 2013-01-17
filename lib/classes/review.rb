require 'classes/resource'

module PCR
  class Review
    include PCR::Resource
    attr_reader :instructor, :num_reviewers, :num_students, :retrieved,
                :comments, :id

    def initialize(path)
      @path = path

      # Hit api
      json = PCR.get_json(path)

      # Assign attrs
      attrs = %(instructor num_reviewers num_students amount_learned comments
                retrieved id)
      set_attrs(attrs, json)

      # Assign ratings
      ratings = json['ratings']
      ratings.each do |name, val|
        self.instance_variable_set("@#{name}", val)
        attr_accessor name
      end
    end
  end
end
