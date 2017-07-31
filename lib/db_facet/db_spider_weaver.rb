
##################
# DbSpiderWeaver #
##################

class DbSpiderWeaver
  VALIDATE_INSERTS = false
  IMPORT_OPTS = {timestamps: true, validate: false, recursive: false}

  def initialize data_tree, timer: false
    @root_node = DbSpiderWriterNode.new data_tree
    @translation_buffer = []
    @timer = if timer
      ProcTimer.new "DbSpiderWeaver", own_logfile: false
    end
  end

  def weave!
    @timer.try :start
    ActiveRecord::Base.transaction do
      traverse [@root_node]
      insert_translations
    end
    @timer.try :finish
    @root_node.id
  end

  private

  def traverse nodes, parent = nil, parent_reflection: nil
    return if nodes.blank?
    set_foreign_keys_on_children nodes, parent_reflection, parent
    insert nodes
    update_foreign_key_on_parent parent, parent_reflection, nodes
    nodes.each do |node|
      node.reflection_nodes.each do |ref, ref_nodes|
        traverse ref_nodes, node, parent_reflection: ref
      end
    end
  end

  def set_foreign_keys_on_children nodes, reflection, parent
    return unless parent and
                  reflection and
                  reflection.macro.in? [:has_many, :has_one]

    if parent.id.blank?
      raise "no fk val for #{parent.model} #{parent.data.to_json}"
    end

    fk_data = {reflection.foreign_key.to_s => parent.id}

    if reflection.options[:as] # polymorphic
      fk_data[reflection.type] = nodes.first.model.name
    end

    nodes.each {|n| n.data.merge! fk_data}

    nodes
  end

  def update_foreign_key_on_parent parent, reflection, nodes
    return unless parent and
                  reflection and
                  reflection.macro == :belongs_to
    child_node = nodes.first
    atts = {}
    atts[reflection.foreign_key] = child_node[:data][child_node[:class_name].constantize.primary_key]
    if reflection.options[:polymorphic]
      atts[reflection.foreign_type] = child_node[:class_name]
    end
    parent.update_columns atts
  end

  def insert nodes
    raise 'blank nodes' if nodes.blank?

    model = nodes.first.model

    atts_list = nodes.map &:insert_data

    validate model, atts_list if VALIDATE_INSERTS

    result = model.import atts_list, IMPORT_OPTS
    check_insert result, model, nodes.length

    nodes.each_with_index {|node, idx| node.id = result.ids[idx].to_i}
    @translation_buffer << nodes if model.translates?
  end

  def check_insert result, model, length
    if result.failed_instances.any?
      raise "Insert failed for model #{model}. failed_instances: #{ result.failed_instances.map{|int| int.errors.messages } }"
    end
    if result.num_inserts == 0
      raise "Insert failed for model #{model}: num_inserts = #{result.num_inserts}"
    end
    if result.ids.length < length
      raise "Insert failed for model #{model}: ids.length < nodes.length #{result.ids.length}/#{length}"
    end
  end

  def validate model, atts_list
    atts_list.each do |atts|
      inst = model.new atts
      unless inst.valid?
        puts "INVALID OBJ: #{model.name} #{atts} #{inst.errors.messages}"
      end
    end
  end

  def insert_translations
    n = @translation_buffer.flatten.group_by{|node| node.t_model}
    n.each_pair do |t_model, nodes|
      t_model.import nodes.map(&:t_data), IMPORT_OPTS
    end
  end
end


######################
# DbSpiderWriterNode #
######################


