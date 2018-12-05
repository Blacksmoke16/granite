require "./collection"
require "./association_collection"
require "./associations"
require "./callbacks"
require "./columns"
require "./query/executors/base"
require "./query/**"
require "./querying"
require "./settings"
require "./table"
require "./transactions"
require "./migrator"
require "./select"
require "./version"
require "./adapters"

# Granite::Base is the base class for your model objects.
class Granite::Base
  include Associations
  include Callbacks
  include Transactions
  include Migrator
  include Select
  include Columns
  include Table

  extend Columns::Class
  extend Table::Class

  disable_granite_docs? def set_attributes(result : DB::ResultSet)
    # Loading from DB means existing records.
    @new_record = false
    {% for column in @type.instance_vars.select { |ivar| ivar.annotation(Granite::Column) } %}
      self.{{column.id}} = result.read({{column.type}})
    {% end %}
    self
  end

  disable_granite_docs? def set_attributes(hash : Hash(String | Symbol, Granite::Columns::Type))
    # Loading from DB means existing records.
    @new_record = false
    self
  end

  extend Querying
  extend Query::BuilderMethods

  # extend Transactions::ClassMethods

  macro inherited
    include JSON::Serializable
    include YAML::Serializable
    macro finished
      __process_select
      __process_querying
      # __process_transactions
      __process_migrator
    end
  end

  def initialize(**args : Object)
    set_attributes(args.to_h)
  end

  def initialize(args : Hash(Symbol | String, DB::Any))
    set_attributes(args)
  end

  def initialize
  end
end
