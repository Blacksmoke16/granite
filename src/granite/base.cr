require "./collection"
require "./association_collection"
require "./associations"
require "./callbacks"
require "./fields"
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
  extend Fields
  include Table
  include Transactions
  include Migrator
  include Select

  disable_granite_docs? def set_attributes(result : DB::ResultSet)
    # Loading from DB means existing records.
    @new_record = false
    {% for column in @type.instance_vars.select { |ivar| ivar.annotation(Granite::Column) } %}
      self.{{column.id}} = result.read({{column.type}})
    {% end %}
    self
  end

  disable_granite_docs? def set_attributes(hash : Hash(String | Symbol, Granite::Fields::Type))
    # Loading from DB means existing records.
    @new_record = false
    {% for column in @type.instance_vars.select { |ivar| ivar.annotation(Granite::Column) } %}
      self.{{column.id}} = {% if column.type.nilable? %} hash[{{column.symbolize}}]? {% else %} hash[{{column.symbolize}}] {% end %}
      {{debug}}
    {% end %}
    self
  end

  def primary_value
    {% begin %}
      {% pk = @type.instance_vars.find { |ivar| ivar.annotation(Granite::PrimaryKey) } %}
      {% if pk %}
        @{{pk.id}}
      {% else %}
        nil
      {% end %}
    {% end %}
  end

  def values
    {% begin %}
      {% fields = @type.instance_vars.select { |ivar| ivar.annotation(Granite::Column) } %}
      pp {{fields.map(&.id)}}
    {% end %}
  end

  def self.quoted_table_name : String
    @@adapter.quote table_name
  end

  extend Querying
  extend Query::BuilderMethods
  extend Transactions::ClassMethods

  macro inherited
    include JSON::Serializable
    include YAML::Serializable
    macro finished
      __process_select
      __process_querying
      __process_transactions
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
