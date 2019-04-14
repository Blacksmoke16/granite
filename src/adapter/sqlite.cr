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

  def insert(table_name : String, columns : Array(Granite::Columns::ClassMethods::ColumnBase), params, lastval : String? = nil) : Int64
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
      return lastval ? db.scalar(last_val()).as(Int64) : -1_i64
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
