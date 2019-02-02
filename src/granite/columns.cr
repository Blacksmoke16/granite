require "json"

module Granite::Columns
  alias SupportedArrayTypes = Array(String) | Array(Int16) | Array(Int32) | Array(Int64) | Array(Float32) | Array(Float64) | Array(Bool)
  alias SupportedCustomTypes = UUID | JSON::Any
  alias Type = DB::Any | SupportedArrayTypes | SupportedCustomTypes

  module ClassMethods
    abstract struct ColumnBase; end

    private record ColumnInfo(T) < ColumnBase, name : String, nilable : Bool, auto : Bool = false, primary : Bool = false, default : T? = nil, type : T.class = T

    def primary_key : ColumnBase
      columns.find(ColumnInfo(Int64).new "id", false, true, true) { |f| f.primary }
    end

    protected def columns : Array(ColumnBase)
      columns = [] of ColumnBase
      {% begin %}
        {% fields = @type.instance_vars.select { |ivar| ivar.annotation(Granite::Column) } %}
        {% raise "Composite primary keys are not yet supported." if fields.select { |ivar| ann = ivar.annotation(Granite::Column); ann && ann[:primary] }.size > 1 %}
        {% for field in fields %}
          {% type = field.type.union? ? field.type.union_types.reject { |t| t == Nil }.first : field.type %}
          {% col_ann = field.annotation(Granite::Column) %}
          {% auto = col_ann && col_ann[:auto] ? col_ann[:auto] : false %}
          {% primary = col_ann && col_ann[:primary] ? col_ann[:primary] : false %}
          {% auto = col_ann[:auto] == nil && primary %}
          {% raise "Primary key '#{field.name}' of '#{@type.name}' must be nilable." if primary && !field.type.nilable? %}
          columns << ColumnInfo({{type}}).new({{field.stringify}}, {{field.type.nilable?}}, {{auto}}, {{primary}}, {{field.default_value}})
        {% end %}
      {% end %}
      columns
    end
  end

  private def primary_value
    {% begin %}
      {% pk = @type.instance_vars.find { |ivar| ann = ivar.annotation(Granite::Column); ann && ann[:primary] } %}
      {% if pk %} @{{pk.id}} {% else %} nil {% end %}
    {% end %}
  end

  private def values
    {% begin %}
      {% values = @type.instance_vars.select { |ivar| ivar.annotation(Granite::Column) } %}
      {{ !values.empty? ? values.map(&.id) : "[] of DB::Any".id }}
    {% end %}
  end
end
