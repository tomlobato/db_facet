class DbSpiderWriterNode

  def initialize reader_node
    @r_node = reader_node
  end

  def id=(v)
    data[pk] = v
  end

  def id
    data[pk]
  end

  def model
    @model ||= @r_node[:class_name].constantize
  end

  def pk
    model.primary_key
  end

  def reflections
    @r_node[:reflections]
  end

  def reflection_nodes
    rn = {}
    reflections.each_pair do |ref_name, reader_nodes|
      rn[model.reflections[ref_name]] = reader_nodes.map{|reader_node|
        DbSpiderWriterNode.new reader_node
      }
    end
    rn
  end

  def data
    @r_node[:data]
  end

  def insert_data
    data.slice *model.column_names
  end

  def t_data
    data.slice(*t_cols).merge(
      locale: 'pt-BR',
      t_fk => id
    )
  end

  def t_fk
    @t_fk ||= t_model.reflections[:globalized_model].foreign_key
  end

  def t_model
    @t_model ||= model.translation_class
  end

  def t_cols
    @t_cols ||= model.translated_attribute_names.map &:to_s
  end

  def update_columns atts
    raise "Trying to update record without primary key: #{model} #{atts}" if id.blank?
    model.where(id: id).update_columns atts
  end

end
