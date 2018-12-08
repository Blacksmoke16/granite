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
      @@adapter.quote table_name
    end

    disable_granite_docs? def quote(name : String) : String
      @@adapter.quote name
    end
  end

  # specify the database adapter you will be using for this model.
  # mysql, pg, sqlite, etc.
  macro adapter(name)
    class_getter adapter : Granite::Adapter::Base = Granite::Adapters.registered_adapters.find { |adapter| adapter.name == {{name.stringify}} } || raise "No registered adapter with the name '{{name.id}}'"
  end

  # specify the table name to use otherwise it will use the model's name
  macro table_name(name)
    class_getter table_name : String = {{name.stringify}}
  end

  disable_granite_docs? protected def set_attributes(result : DB::ResultSet)
    # Loading from DB means existing records.
    @new_record = false
    {% for column in @type.instance_vars.select { |ivar| ivar.annotation(Granite::Column) } %}
      {% ann = column.annotation(Granite::Column) %}
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

  disable_granite_docs? protected def set_attributes(hash : Hash(Symbol, DB::Any)) : self
    {% for column in @type.instance_vars.select { |ivar| ivar.annotation(Granite::Column) } %}
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

  disable_granite_docs? protected def set_attributes(hash : Hash(String, DB::Any)) : self
    {% for column in @type.instance_vars.select { |ivar| ivar.annotation(Granite::Column) } %}
      if val = hash[{{column.stringify}}]?
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
