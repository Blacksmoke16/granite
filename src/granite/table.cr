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
  # specify the database adapter you will be using for this model.
  # mysql, pg, sqlite, etc.
  macro adapter(name)
    class_getter adapter : Granite::Adapter::Base = Granite::Adapters.registered_adapters.find { |adapter| adapter.name == {{name.stringify}} } || raise "No registered adapter with the name '{{name.id}}'"
  end

  # specify the table name to use otherwise it will use the model's name
  macro table_name(name)
    class_getter table_name : String = {{name.stringify}}
  end

  module Class
    def quoted_table_name : String
      @@adapter.quote table_name
    end
  end
end
