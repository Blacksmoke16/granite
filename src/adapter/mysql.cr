require "./base"
require "mysql"
require "uuid"
require "uuid/json"

# :nodoc:
abstract struct MySql::Type
  def self.type_for(t : ::UUID.class)
    MySql::Type::UUID
  end

  decl_type UUID, 0xfeu8, ::UUID do
    def self.write(packet, v : ::UUID)
      packet.write_lenenc_string v.to_s
    end

    def self.read(packet)
      packet.read_lenenc_string
    end
  end
end

# :nodoc:
class MySql::ResultSet
  def read(t : ::UUID.class)
    ::UUID.new(read(String))
  end

  def read(t : UUID?)
    if v = read(String?)
      UUID.new(v)
    end
  end
end

# Mysql implementation of the Adapter
class Granite::Adapter::Mysql < Granite::Adapter::Base
  QUOTING_CHAR       = '`'
  VALUE_QUOTING_CHAR = '\''

  module Schema
    TYPES = {
      "AUTO_Int32" => "INT NOT NULL AUTO_INCREMENT",
      "AUTO_Int64" => "BIGINT NOT NULL AUTO_INCREMENT",
      "AUTO_UUID"  => "CHAR(36)",
      "UUID"       => "CHAR(36)",
      "created_at" => "TIMESTAMP DEFAULT CURRENT_TIMESTAMP",
      "updated_at" => "TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP",
    }
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
      db.using_connection do |conn|
        conn.exec statement, params
        if lastval
          return conn.scalar(last_val()).as(Int64)
        else
          return -1_i64
        end
      end
    end
  end

  def import(table_name : String, primary_name : String, auto : String, fields, model_array, **options)
    params = [] of DB::Any

    statement = String.build do |stmt|
      stmt << "INSERT"
      stmt << " IGNORE" if options["ignore_on_duplicate"]?
      stmt << " INTO #{quote(table_name)} ("
      stmt << fields.map { |field| quote(field) }.join(", ")
      stmt << ") VALUES "

      model_array.each do |model|
        model.set_timestamps
        next unless model.valid?
        stmt << "("
        stmt << Array.new(fields.size, '?').join(',')
        params.concat fields.map { |field| model.read_attribute field }
        stmt << "),"
      end
    end.chomp(',')

    if options["update_on_duplicate"]?
      if columns = options["columns"]?
        statement += " ON DUPLICATE KEY UPDATE "
        columns << "updated_at" if fields.includes? "updated_at"
        columns.each do |key|
          statement += "#{quote(key)}=VALUES(#{quote(key)}), "
        end
        statement = statement.chomp(", ")
      end
    end

    log statement, params

    open do |db|
      db.exec statement, params
    end
  end

  private def last_val
    return "SELECT LAST_INSERT_ID()"
  end

  private def convert_placeholders(clause : String) : String
    clause = clause.gsub(/\=\ \$\d+/, '?') if clause =~ /\$\d+/
    clause
  end
end
