# Adds a :nodoc: to granite methods/constants if `DISABLE_GRANTE_DOCS` ENV var is true
macro disable_granite_docs?(stmt)
  {% unless env("DISABLE_GRANITE_DOCS") == "false" %}
    # :nodoc:
    {{stmt.id}}
  {% else %}
    {{stmt.id}}
  {% end %}
end

module Granite::Table
  module ClassMethods
    disable_granite_docs? def quoted_table_name : String
      adapter.quote table
    end

    disable_granite_docs? def quote(name : String) : String
      adapter.quote name
    end

    def table : String
      {% begin %}
        {% table_ann = @type.annotation(Granite::Model) %}
        {{table_ann && table_ann[:table] != nil ? table_ann[:table] : @type.name.underscore.stringify + "s"}}
      {% end %}
    end

    # Returns the adapter to use for this model
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

  disable_granite_docs? def set_attributes(result : DB::ResultSet) : self
    @new_record = false
    {% for column in @type.instance_vars.select { |ivar| ivar.annotation(Granite::Column) } %}
      self.{{column.id}} =
        {% if column.type == UUID? %}
          if val = result.read
            UUID.new val.as(String)
          end
        {% elsif column.type == UUID %}
          UUID.new result.read.as(String)
        {% else %}
          result.read({{column.type}})
        {% end %}
    {% end %}
    self
  end

  disable_granite_docs? def set_attributes(hash : Hash(Symbol, DB::Any)) : self
    {% for column in @type.instance_vars %}
      if val = hash[{{column.symbolize}}]?
        if val.is_a?({{column.type}})
          @{{column.id}} = val
        else
          raise "Expected {{column.id}} to be {{column.type}} but got #{typeof(val)}."
        end
      end
    {% end %}
    self
  end
end
