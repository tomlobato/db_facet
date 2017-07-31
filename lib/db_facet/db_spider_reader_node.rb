class DbSpiderReaderNode
  attr_reader :rec

  def initialize rec, data_columns = nil
    @rec = rec
    @data_columns = data_columns || @rec.class.column_names
    @ref_nodes = {}
    @traversed = false
  end

  def excl_data_cols excl
    @data_columns -= [excl]
  end

  def traversed?
    @traversed
  end

  def traversed!
    @traversed = true
  end

  def data_tree
    {
      data:        data,
      class_name:  @rec.class.name,
      original_id: @rec.id,
      reflections: reflections_data
    }
  end

  def reflections_data
    rd = {}
    @ref_nodes.each_pair do |ref_name, nodes|
      rd[ref_name] = nodes.map &:data_tree
    end
    rd
  end

  def reflections
    @rec.class.reflections.values
  end

  def reflection_records ref
    recs = @rec.send ref.name
    [recs].flatten.compact
  end

  def add_reflection_node node, ref
    @ref_nodes[ref.name] ||= []
    @ref_nodes[ref.name] << node
  end

  def eql? other # used by Hash to compare keys
    @rec.eql? other
  end

  def data
    @rec.attributes.slice *@data_columns
  end

  def children
    reflections
      .map{|ref| @ref_nodes[ref.name].to_a}
      .flatten
      .compact
      .sort_by{|n| n.rec.class.name}
  end
end
