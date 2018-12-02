require "json"

module Granite::Fields
  alias SupportedArrayTypes = Array(String) | Array(Int16) | Array(Int32) | Array(Int64) | Array(Float32) | Array(Float64) | Array(Bool)
  alias Type = DB::Any | SupportedArrayTypes
  TIME_FORMAT_REGEX = /\d{4,}-\d{2,}-\d{2,}\s\d{2,}:\d{2,}:\d{2,}/

  def primary_key : String?
    {% begin %}
      {% pk = @type.instance_vars.find { |ivar| ivar.annotation(Granite::PrimaryKey) } %}
      {{pk ? pk.stringify : "id"}}
    {% end %}
  end

  def fields : Array(String)
    {% begin %}
      {% fields = @type.instance_vars.select { |ivar| ivar.annotation(Granite::Column) } %}
      {{ !fields.empty? ? fields.map(&.stringify) : "[] of String".id }}
    {% end %}
  end
end
