class DbSpiderNodeSet
  attr_reader :count, :uniq_count

  def initialize
    @set = {}
    @count = 0
    @uniq_count = 0
  end

  def find_or_create *args
    @count += 1
    obj = args[0]
    if node = @set[obj]
      node
    else
      @uniq_count += 1
      @set[obj] = DbSpiderReaderNode.new *args
    end
  end

end
