require "../granite"
require "db"

# The Base Adapter specifies the interface that will be used by the model
# objects to perform actions against a specific database.  Each adapter needs
# to implement these methods.
abstract class Granite::Adapter::Base
  getter name : String
  getter url : String
  private property _database : DB::Database?

  def initialize(connection_hash : NamedTuple(url: String, name: String))
    @name = connection_hash[:name]
    @url = connection_hash[:url]
  end

  def database : DB::Database
    @_database ||= DB.open(@url)
  end

  def open(&block)
    yield database
  end

  def log(query : String, params = [] of String) : Nil
    Granite.settings.logger.info "#{query}: #{params}"
  end

  # select performs a query against a table.  The query object containes table_name,
  # fields (configured using the sql_mapping directive in your model), and an optional
  # raw query string.  The clause and params is the query and params that is passed
  # in via .all() method
  def select(table : String, clause = "", params = [] of DB::Any, &block) : Nil
    clause = convert_placeholders clause
    statement = String.build do |stmt|
      stmt << "SELECT * FROM #{quote(table)} #{clause}"
    end

    log statement, params

    open do |db|
      db.query statement, params do |rs|
        yield rs
      end
    end
  end

  # remove all rows from a table and reset the counter on the id.
  def clear(table_name : String) : DB::ExecResult
    statement = "TRUNCATE TABLE #{quote(table_name)}"

    log statement

    open do |db|
      db.exec statement
    end
  end

  # This will update a row in the database.
  def update(table_name : String, primary_name : String, columns : Array(Granite::Columns::ClassMethods::ColumnBase), params) : DB::ExecResult
    statement = String.build do |stmt|
      stmt << "UPDATE #{quote(table_name)} SET "
      stmt << columns.map { |c| "#{quote(c.name)} = ?" }.join(", ")
      stmt << " WHERE #{quote(primary_name)} = ?"
    end
    statement = convert_placeholders statement

    log statement, params

    open do |db|
      db.exec statement, params
    end
  end

  # This will delete a row from the database.
  def delete(table_name : String, primary_name, value)
    statement = convert_placeholders "DELETE FROM #{quote(table_name)} WHERE #{quote(primary_name)} = ?"

    log statement, value

    open do |db|
      db.exec statement, value
    end
  end

  # Prepared statement placehlder conversion
  abstract def convert_placeholders(clause : String) : String

  # This will insert an array of models as one insert statement
  abstract def import(table_name : String, primary_name : String, auto : String, columns : Array(ColumnBase), model_array, **options)

  module Schema
    TYPES = {
      "Bool"    => "BOOL",
      "Float32" => "FLOAT",
      "Float64" => "REAL",
      "Int32"   => "INT",
      "Int64"   => "BIGINT",
      "String"  => "VARCHAR(255)",
      "Time"    => "TIMESTAMP",
    }
  end

  # Use macro in order to read a constant defined in each subclasses.
  macro inherited
    # quotes table and column names
    def quote(name : String) : String
      char = QUOTING_CHAR
      char + name.gsub(char, "#{char}#{char}") + char
    end

    # quotes a value of a given type
    def quote_value(value) : String
      String.build do |str|
        str << QUOTING_CHAR
        str << value
        str << QUOTING_CHAR
      end
    end

    # quotes a value of a given type
    def quote_value(value : Number? | Bool?)
      value
    end

    # quotes a value of a given type
    def quote_value(value : Array) : String
      String.build do |str|
        str << VALUE_QUOTING_CHAR
        str << '{'
        value.each do |v|
          str << v
          str << ','
        end
        str.chomp! 44_u8
        str << '}'
        str << VALUE_QUOTING_CHAR
      end
    end

    # converts the crystal class to database type of this adapter
    def self.schema_type?(key : String)
      Schema::TYPES[key]? || Granite::Adapter::Base::Schema::TYPES[key]?
    end
  end
end
