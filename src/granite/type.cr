module Granite::Type
  extend self

  # :nodoc:
  PRIMITIVES = {
    Int8    => ".read",
    Int16   => ".read",
    Int32   => ".read",
    Int64   => ".read",
    UInt8   => ".read",
    UInt16  => ".read",
    UInt32  => ".read",
    UInt64  => ".read",
    Float32 => ".read",
    Float64 => ".read",
    Bool    => ".read",
    String  => ".read",
    Time    => ".read",
  }

  CUSTOM = {
    UUID  => "UUID.new result.read.as(String)",
    UUID? => "(val = result.read) ? UUID.new val.as(String) : nil",
  }

  {% for type, method in PRIMITIVES %}
    # Converts a `DB::ResultSet` to `{{type}}`.
    def convert_type(result : DB::ResultSet, t : {{type.id}}.class) : {{type.id}}
      result{{method.id}} {{type}}
    end

    # Converts a `DB::ResultSet` to `{{type}}?`.
    def convert_type(result : DB::ResultSet, t : {{type.id}}?.class) : {{type.id}}?
      result{{method.id}} {{type}}?
    end
  {% end %}

  {% for type, method in CUSTOM %}
    # Converts a `DB::ResultSet` to `{{type}}`.
    def convert_type(result : DB::ResultSet, t : {{type.id}}.class) : {{type.id}}
      {{method.id}}
    end

    def convert_type(result : DB::ResultSet, t : {{type.id}}?.class) : {{type.id}}?
      {{method.id}}
    end
  {% end %}
end
