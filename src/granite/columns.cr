require "json"

module Granite::Columns
  alias SupportedArrayTypes = Array(String) | Array(Int16) | Array(Int32) | Array(Int64) | Array(Float32) | Array(Float64) | Array(Bool)
  alias SupportedCustomTypes = UUID | JSON::Any
  alias Type = DB::Any | SupportedArrayTypes | SupportedCustomTypes

  module ClassMethods
    abstract struct ColumnBase; end

    private record ColumnInfo(T) < ColumnBase, name : String, nilable : Bool, auto : Bool = false, primary : Bool = false, default : T? = nil, type : T.class = T

    protected def primary_key : ColumnBase
      columns.find(ColumnInfo(Int64).new "id", false, true, true) { |f| f.primary }
    end

    protected def columns : Array(ColumnBase)
      columns = [] of ColumnBase
      {% begin %}
        {% fields = @type.instance_vars.select { |ivar| ivar.annotation(Granite::Column) } %}
        {% for field in fields %}
          {% type = field.type.union? ? field.type.union_types.reject { |t| t == Nil }.first : field.type %}
          {% pk_ann = field.annotation(Granite::Column) %}
          {% auto = pk_ann && pk_ann[:auto] ? pk_ann[:auto] : false %}
          {% primary = pk_ann && pk_ann[:primary] ? pk_ann[:primary] : false %}
          {% raise "Primary key #{field.name} of #{@type.name} should be nilable." if primary && !field.type.nilable? %}
          columns << ColumnInfo({{type}}).new({{field.stringify}}, {{field.type.nilable?}}, {{!auto && primary ? true : auto}}, {{primary}}, {{field.default_value}})
        {% end %}
      {% end %}
      columns
    end
  end

  private def primary_value
    {% begin %}
      {% pk = @type.instance_vars.find { |ivar| ivar = ivar.annotation(Granite::Column); ivar && ivar[:primary] } %}
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
