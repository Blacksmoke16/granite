module Granite::Table
  module ClassMethods
    def quoted_table_name : String
      adapter.quote table
    end

    def quote(name : String) : String
      adapter.quote name
    end

    # Returns the name of the table for `self`
    # defaults to the model's name underscored + 's'
    def table : String
      {% begin %}
        {% table_ann = @type.annotation(Granite::Model) %}
        {{table_ann && table_ann[:table] != nil ? table_ann[:table] : @type.name.underscore.stringify + 's'}}
      {% end %}
    end

    # Returns the adapter to use for `self`
    # defaults to the first registered adapter is none is given
    def adapter : Granite::Adapter::Base
      {% begin %}
        {% table_ann = @type.annotation(Granite::Model) %}
        {% adapter = table_ann && table_ann[:adapter] != nil ? table_ann[:adapter] : nil %}
        unless {{adapter}}
          if a = Granite::Adapters.registered_adapters.first?
            a = a.name
          end
        else
          a = {{adapter}}
        end
        Granite::Adapters.registered_adapters.find { |adapter| adapter.name == a } || raise "No registered adapter with the name '#{a}'"
      {% end %}
    end
  end

  def set_attributes(result : DB::ResultSet) : self
    @new_record = false
    {% for column in @type.instance_vars.select { |ivar| ivar.annotation(Granite::Column) } %}
      self.{{column.id}} = Granite::Type.convert_type result, {{column.type}}
    {% end %}
    self
  end

  def set_attributes(hash : Hash(Symbol, DB::Any)) : self
    {% for column in @type.instance_vars.reject { |ivar| ann = ivar.annotation(Granite::Column); ann && ann[:primary] && (ann[:auto] == true || ann[:auto] == nil) } %}
      if val = hash[{{column.symbolize}}]?
        if val.is_a? {{column.type}}
          @{{column.id}} = val
        else
          raise "Expected {{column.id}} to be {{column.type}} but got #{typeof(val)}."
        end
      end
    {% end %}
    self
  end
end
