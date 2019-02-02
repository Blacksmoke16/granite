require "./base"
require "sqlite3"
require "uuid"
require "uuid/json"

# :nodoc:
class SQLite3::Statement < DB::Statement
  private def bind_arg(index, value : UUID)
    _uuid = value.to_s
    check LibSQLite3.bind_text(self, index, _uuid, _uuid.bytesize, nil)
  end
end

# Sqlite implementation of the Adapter
class Granite::Adapter::Sqlite < Granite::Adapter::Base
  QUOTING_CHAR       = '"'
  VALUE_QUOTING_CHAR = '\''

  module Schema
    TYPES = {
      "AUTO_Int32" => "INTEGER NOT NULL",
      "AUTO_Int64" => "INTEGER NOT NULL",
      "AUTO_UUID"  => "CHAR(36)",
      "UUID"       => "CHAR(36)",
      "Int32"      => "INTEGER",
      "Int64"      => "INTEGER",
      "created_at" => "VARCHAR",
      "updated_at" => "VARCHAR",
    }
  end

  # remove all rows from a table and reset the counter on the id.
  def clear(table_name : String) : DB::ExecResult
    statement = "DELETE FROM #{quote(table_name)}"

    log statement

    open do |db|
      db.exec statement
    end
  end

  def insert(table_name : String, columns : Array(Granite::Columns::ClassMethods::ColumnBase), params, lastval) : Int64
    statement = String.build do |stmt|
      stmt << "INSERT INTO #{quote(table_name)} ("
      stmt << columns.map { |c| "#{quote(c.name)}" }.join(", ")
      stmt << ") VALUES ("
      stmt << ("?,"*columns.size).chomp(',')
      stmt << ")"
    end

    log statement, params

    open do |db|
      db.exec statement, params
      if lastval
        return db.scalar(last_val()).as(Int64)
      else
        return -1_i64
      end
    end
  end

  def import(table_name : String, primary_name : String, auto : String, fields, model_array, **options)
    params = [] of DB::Any

    statement = String.build do |stmt|
      stmt << "INSERT "
      if options["update_on_duplicate"]?
        stmt << "OR REPLACE "
      elsif options["ignore_on_duplicate"]?
        stmt << "OR IGNORE "
      end
      stmt << "INTO #{quote(table_name)} ("
      stmt << fields.map { |field| quote(field) }.join(", ")
      stmt << ") VALUES "

      model_array.each do |model|
        next unless model.valid?
        model.set_timestamps
        stmt << '('
        stmt << Array.new(fields.size, '?').join(',')
        params.concat fields.map { |field| model.read_attribute field }
        stmt << "),"
      end
    end.chomp(',')

    log statement, params

    open do |db|
      db.exec statement, params
    end
  end

  private def last_val : String
    return "SELECT LAST_INSERT_ROWID()"
  end

  private def convert_placeholders(clause : String) : String
    clause = clause.gsub(/(?!\=\ )(\$\d+)/, '?') if clause =~ /\$\d+/
    clause
  end
end
