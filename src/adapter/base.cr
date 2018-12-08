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
  def select(query : Granite::Select::Container, clause = "", params = [] of DB::Any, &block)
    clause = ensure_clause_template(clause)
    statement = query.custom ? "#{query.custom} #{clause}" : String.build do |stmt|
      stmt << "SELECT "
      stmt << query.columns.map { |c| "#{quote(query.table_name)}.#{quote(c.name)}" }.join(", ")
      stmt << " FROM #{quote(query.table_name)} #{clause}"
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

  # Place holder conversion
  abstract def ensure_clause_template(clause : String) : String

  # This will insert a row in the database and return the id generated.
  abstract def insert(table_name : String, columns : Array(ColumnBase), params, lastval) : Int64

  # This will insert an array of models as one insert statement
  abstract def import(table_name : String, primary_name : String, auto : String, columns : Array(ColumnBase), model_array, **options)

  # This will update a row in the database.
  abstract def update(table_name : String, primary_name : String, columns : Array(ColumnBase), params)

  # This will delete a row from the database.
  abstract def delete(table_name : String, primary_name : String, value)

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
      char = VALUE_QUOTING_CHAR
      "#{char}#{value}#{char}"
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
