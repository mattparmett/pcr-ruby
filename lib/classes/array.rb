#Add useful array methods
class Array
  def binary_search(target)
    self.search_iter(0, self.length-1, target)
  end

  def search_iter(lower, upper, target)
    return -1 if lower > upper
    mid = (lower+upper)/2
    if (self[mid] == target)
      mid
    elsif (target < self[mid])
      self.search_iter(lower, mid-1, target)
    else
      self.search_iter(mid+1, upper, target)
    end
  end
end