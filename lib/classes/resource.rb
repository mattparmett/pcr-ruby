module PCR
  module Resource
    def set_attrs(attrs, json)
      attrs.each do |attr|
        self.instance_variable_set("@#{attr}", json['result'][attr] || json[attr])
      end
    end
  end
end
