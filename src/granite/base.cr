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

  extend Columns::ClassMethods
  extend Table::ClassMethods
  extend Transactions::ClassMethods

  extend Querying
  extend Query::BuilderMethods

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
