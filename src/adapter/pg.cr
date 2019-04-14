require "./base"
require "pg"

# PostgreSQL implementation of the Adapter
class Granite::Adapter::Pg < Granite::Adapter::Base
  QUOTING_CHAR       = '"'
  VALUE_QUOTING_CHAR = '\''

  module Schema
    TYPES = {
      "AUTO_Int32"     => "SERIAL",
      "AUTO_Int64"     => "BIGSERIAL",
      "AUTO_UUID"      => "UUID",
      "UUID"           => "UUID",
      "JSON::Any"      => "JSONB",
      "created_at"     => "TIMESTAMP",
      "updated_at"     => "TIMESTAMP",
      "Array(String)"  => "TEXT[]",
      "Array(Int16)"   => "SMALLINT[]",
      "Array(Int32)"   => "INT[]",
      "Array(Int64)"   => "BIGINT[]",
      "Array(Float32)" => "REAL[]",
      "Array(Float64)" => "DOUBLE PRECISION[]",
      "Array(Bool)"    => "BOOLEAN[]",
    }
  end

  def insert(table_name : String, columns : Array(Granite::Columns::ClassMethods::ColumnBase), params, lastval : String? = nil)
    column_names : Array(String) = columns.map(&.name)
    statement = String.build do |stmt|
      stmt << "INSERT INTO #{quote(table_name)} ("
      stmt << columns.map { |c| "#{quote(c.name)}" }.join(", ")
      stmt << ") VALUES ("
      stmt << columns.map { |c| "$#{column_names.index(c.name).not_nil! + 1}" }.join(", ")
      stmt << ")"

      stmt << " RETURNING #{quote(lastval)}" if lastval
    end

    log statement, params

    open do |db|
      if lastval
        db.scalar(statement, params).as(Int32 | Int64).to_i64
      else
        db.exec statement, params
        -1_i64
      end
    end
  end

  private def convert_placeholders(clause : String) : String
    if clause =~ /=\ \?/
      num_subs = clause.count('?')

      num_subs.times do |i|
        clause = clause.sub(/\=\ \?/, "= $#{i + 1}")
      end
    end

    clause
  end
end
