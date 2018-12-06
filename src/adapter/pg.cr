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
      "UUID"           => "UUID",
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

  def insert(table_name : String, columns : Array(Granite::Columns::Class::ColumnBase), params, lastval) : Int64
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

  def import(table_name : String, primary_name : String, auto : String, fields, model_array, **options)
    params = [] of DB::Any
    # PG fails when inserting null into AUTO INCREMENT PK field.
    # If AUTO INCREMENT is TRUE AND all model's pk are nil, remove PK from fields list for AUTO INCREMENT to work properly
    fields.reject! { |field| field == primary_name } if model_array.all? { |m| m.to_h[primary_name].nil? } && auto == "true"
    index = 0

    statement = String.build do |stmt|
      stmt << "INSERT"
      stmt << " INTO #{quote(table_name)} ("
      stmt << fields.map { |field| quote(field) }.join(", ")
      stmt << ") VALUES "

      model_array.each do |model|
        model.set_timestamps
        next unless model.valid?
        stmt << '('
        stmt << fields.map_with_index { |_f, idx| "$#{index + idx + 1}" }.join(',')
        params.concat fields.map { |field| model.read_attribute field }
        stmt << "),"
        index += fields.size
      end
    end.chomp(',')

    if options["update_on_duplicate"]?
      if columns = options["columns"]?
        statement += " ON CONFLICT (#{quote(primary_name)}) DO UPDATE SET "
        columns << "updated_at" if fields.includes? "updated_at"
        columns.each do |key|
          statement += "#{quote(key)}=EXCLUDED.#{quote(key)}, "
        end
      end
      statement = statement.chomp(", ")
    elsif options["ignore_on_duplicate"]?
      statement += " ON CONFLICT DO NOTHING"
    end

    log statement, params

    open do |db|
      db.exec statement, params
    end
  end

  # This will update a row in the database.
  def update(table_name : String, primary_name : String, columns : Array(ColmunBase), params)
    column_names : Array(String) = columns.map(&.name)
    statement = String.build do |stmt|
      stmt << "UPDATE #{quote(table_name)} SET "
      stmt << columns.map { |c| "#{quote(c.name)}=$#{column_names.index(c.name).not_nil! + 1}" }.join(", ")
      stmt << " WHERE #{quote(primary_name)}=$#{columns.size + 1}"
    end

    log statement, params

    open do |db|
      db.exec statement, params
    end
  end

  # This will delete a row from the database.
  def delete(table_name : String, primary_name : String, value)
    statement = "DELETE FROM #{quote(table_name)} WHERE #{quote(primary_name)}=$1"

    log statement, value

    open do |db|
      db.exec statement, value
    end
  end

  private def ensure_clause_template(clause : String) : String
    if clause.includes?('?')
      num_subs = clause.count('?')

      num_subs.times do |i|
        clause = clause.sub('?', "$#{i + 1}")
      end
    end

    clause
  end
end
