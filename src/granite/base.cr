require "./adapters"
require "./columns"
require "./migrator"
require "./querying"
require "./settings"
require "./table"
require "./transactions"
require "./version"

# Granite::Base is the base class for your model objects.
class Granite::Base
  include Columns
  include Migrator
  include Table
  include Transactions

  extend Columns::ClassMethods
  extend Table::ClassMethods
  extend Transactions::ClassMethods
  extend Migrator::ClassMethods
  extend Querying

  macro inherited
    include JSON::Serializable
    include YAML::Serializable
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
