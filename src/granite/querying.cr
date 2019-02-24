module Granite::Querying
  class NotFound < Exception
  end

  # Create the from_sql method
  def from_sql(result : DB::ResultSet) : self
    model = {{@type.name.id}}.new
    model.set_attributes(result)
    model
  end

  def all(clause = "", params = [] of DB::Any)
    rows = [] of self
    adapter.select(table, clause, params) do |results|
      results.each do
        rows << self.from_sql(results)
      end
    end
    return rows
  end

  # First adds a `LIMIT 1` clause to the query and returns the first result
  def first(clause = "", params = [] of DB::Any) : self?
    all([clause.strip, "LIMIT 1"].join(" "), params).first?
  end

  def first!(clause = "", params = [] of DB::Any) : self
    first(clause, params) || raise NotFound.new("No #{{{@type.name.stringify}}} found with first(#{clause})")
  end

  # find returns the row with the primary key specified. Otherwise nil.
  def find(value) : self?
    first("WHERE #{primary_key.name} = ?", value)
  end

  # find returns the row with the primary key specified. Otherwise raises an exception.
  def find!(value) : self
    find(value) || raise Granite::Querying::NotFound.new("No #{{{@type.name.stringify}}} found where #{primary_key.name} = #{value}")
  end

  # find_by returns the first row found that matches the given criteria. Otherwise nil.
  def find_by(**args) : self?
    first("WHERE #{args.map { |name| "#{quote(table)}.#{quote(name.to_s)} = ?" }.join(" AND ")}", args.values.to_a)
  end

  # find_by returns the first row found that matches the given criteria. Otherwise raises an exception.
  def find_by!(**args) : self
    find_by(**args) || raise NotFound.new("No #{{{@type.name.stringify}}} found where #{args.map { |k, v| "#{k} = #{v}" }.join(" and ")}")
  end

  # count returns a count of all the records
  def count : Int32
    scalar "SELECT COUNT(*) FROM #{quoted_table_name}", &.to_s.to_i
  end

  def exec(clause = "")
    adapter.open { |db| db.exec(clause) }
  end

  def query(clause = "", params = [] of DB::Any, &block)
    adapter.open { |db| yield db.query(clause, params) }
  end

  def scalar(clause = "", &block)
    adapter.open { |db| yield db.scalar(clause) }
  end
end
