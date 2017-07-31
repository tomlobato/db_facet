
class DbSpiderRootMerger

  def initialize root_node
    @root_node = root_node
  end

  def merge! data
    root_model = @root_node[:class_name].constantize
    root_model.reflections.each do |ref_name, reflection|
      next unless data[ref_name]

      case data[ref_name]
        when Hash, Array, ActiveRecord::Base
          [data[ref_name]].flatten.each do |ref_data|
            rec = if ref_data.is_a? ActiveRecord::Base
              ref_data
            else
              reflection.klass.new ref_data
            end
            @root_node[:reflections][ref_name] ||= []
            @root_node[:reflections][ref_name] << DbSpiderReaderNode.new(rec).data_tree
          end

        when Proc
          @root_node[:reflections][ref_name].each do |ref_node|
            data[ref_name].call ref_node[:data]
          end

        else
          raise "Invalid value. data[ref_name] must be a Hash, Array of Hash`es or Lambda. Found #{data[ref_name].class} for ref_name #{ref_name}."
      end

      data.delete ref_name
    end

    @root_node[:data].merge! data.stringify_keys
  end

end