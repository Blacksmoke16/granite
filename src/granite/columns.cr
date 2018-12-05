require "json"

module Granite::Columns
  module Class
    abstract struct ColumnBase; end

    private struct ColumnInfo(T) < ColumnBase
      getter nilable : Bool
      getter name : String
      getter type : T.class
      getter auto : Bool = false
      getter primary : Bool = false

      def initialize(@name : String, @nilable : Bool, @auto : Bool = false, @primary : Bool = false, @type : T.class = T)
      end
    end

    def primary_key : ColumnBase
      columns.find(ColumnInfo(Int64).new "id", false, true, true) { |f| f.primary }
    end

    def columns : Array(ColumnBase)
      columns = [] of ColumnBase
      {% begin %}
      {% fields = @type.instance_vars.select { |ivar| ivar.annotation(Granite::Column) } %}
      {% for field in fields %}
        {% type = field.type.union? ? field.type.union_types.reject { |t| t == Nil }.first : field.type %}
        {% pk_ann = field.annotation(Granite::Column) %}
        {% auto = pk_ann && pk_ann[:auto] ? pk_ann[:auto] : false %}
        {% primary = pk_ann && pk_ann[:primary] ? pk_ann[:primary] : false %}
        columns << ColumnInfo({{type}}).new({{field.stringify}}, {{field.type.nilable?}}, {{!auto && primary ? true : auto}}, {{primary}})
      {% end %}
    {% end %}
      columns
    end
  end

  def primary_value
    {% begin %}
      {% pk = @type.instance_vars.find { |ivar| ivar = ivar.annotation(Granite::Column); ivar && ivar[:primary] } %}
      {% if pk %} @{{pk.id}} {% else %} nil {% end %}
    {% end %}
  end

  def values
    {% begin %}
      {% values = @type.instance_vars.select { |ivar| ivar.annotation(Granite::Column) } %}
      {{ !values.empty? ? values.map(&.id) : "[] of DB::Any".id }}
    {% end %}
  end
end
