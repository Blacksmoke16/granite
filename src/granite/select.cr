module Granite::Select
  macro included
    macro inherited
      disable_granite_docs? CONTENT_FIELDS = {} of Nil => Nil
      disable_granite_docs? FIELDS = {} of Nil => Nil
    end
  end

  struct Container
    property custom : String?
    getter table_name, columns

    def initialize(@custom = nil, @table_name = "", @columns = [] of Granite::Columns::ClassMethods::ColumnBase)
    end
  end

  macro select_statement(text)
    @@select.custom = {{text.strip}}

    def self.select
      @@select.custom
    end
  end

  macro __process_select
    @@select = Container.new(table_name: @@table_name, columns: columns)
  end
end
