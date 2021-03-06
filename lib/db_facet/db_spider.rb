
# TODO: Support for :has_and_belongs_to_many and :through.

class DbSpider

  DEFAULT_IGNORE_COLUMNS = [
    %w(id created_at updated_at),
    /password|passwd|pass|token|senha/i,
  ]

  def initialize root_rec,
                 allow_models = nil, # nil allows all
                 keep_columns: {},
                 ignore_columns: DEFAULT_IGNORE_COLUMNS, # unflattened list of regex, strings or symbols
                 allow_root_class_as_child: false

    @root_rec       = root_rec
    @allow_models   = allow_models
    @keep_columns   = keep_columns
    @ignore_columns = ignore_columns

    @node_set = DbSpiderNodeSet.new
    @cache = {data_column: {}}
    @deny_models = []

    unless allow_root_class_as_child
      @deny_models << @root_rec.class.name
    end
  end

  def spide print: false
    root_node = traverse @root_rec, nil
    print_tree root_node if print
    root_node.data_tree
  end

  private

  def traverse rec, parent_rec, parent_node = nil, excl_foreign_key = nil
    data_columns = get_data_columns(rec.class) - [excl_foreign_key]

    node = @node_set.find_or_create rec, data_columns

    unless node.traversed?
      node.reflections.each do |reflection|

        if follow_reflection? reflection, parent_rec

          excl_src, excl_dst = exclude_foreign_key reflection
          node.excl_data_cols excl_src

          node.reflection_records(reflection).each do |reflection_rec|
            reflection_node = traverse reflection_rec, rec, node, excl_dst
            node.add_reflection_node reflection_node, reflection
          end
        end
      end

      node.traversed!
    end

    node
  end

  def exclude_foreign_key ref
    pk = ref.foreign_key
    case ref.macro
    when :belongs_to
      [pk, nil]
    when :has_many, :has_one
      [nil, pk]
    end
  end

  def get_data_columns model
    @cache[:data_column].fetch! model.name do
      cols = model.column_names
                  .select{|col|
                    allow_column? model, col
                  }
      if model.translates?
        cols += model.translated_attribute_names.map(&:to_s)
      end
      cols
    end
  end

  def allow_column? model, col
    if @keep_columns[model.name].to_a.include? col
      return true
    end

    @ignore_columns.to_a.flatten.each do |ignorer|
      if ignorer.is_a? Regexp
        if col =~ ignorer
          return false
        end
      elsif col == ignorer.to_s
        return false
      end
    end

    true
  end

  def follow_reflection? ref, parent_rec
    return false if !ref.macro.in? [:belongs_to, :has_many, :has_one]
    return false if ref.options[:through] # Skip :through assossiations
    return false if !ref.active_record.name == ref.class_name # Skip self joins
    return false if !ref.class_name.in? @allow_models.to_a
    return false if @deny_models.include? ref.class_name
    return false if parent_rec and parent_rec.class == ref.klass # Deny model go back up to the parent class
    true
  end

  def print_tree node, level = 0
    def tab l; "\t" * l; end
    puts "#{ tab level }#{node.rec.class} #{node.rec.id}"
    last_class = nil
    node.children.each do |child_node|
      if last_class and child_node.rec.class != last_class
        puts "#{ tab (level+1) }--"
      end
      last_class = child_node.rec.class
      print_tree child_node, (level+1)
    end
  end

end

