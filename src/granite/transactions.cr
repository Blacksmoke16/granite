require "./exceptions"

module Granite::Transactions
  module ClassMethods
    def clear
      self.adapter.clear table
    end

    def create(**args) : self
      create(args.to_h)
    end

    def create(args : Hash(Symbol | String, DB::Any)) : self
      instance = new
      instance.set_attributes(args)
      instance.save
      instance
    end
  end

  def set_timestamps(*, to time = Time.now, mode = :create)
    {% if @type.instance_vars.select { |ivar| ivar.annotation(Granite::Column) }.map(&.stringify).includes? "created_at" %}
      @created_at = time.to_utc.at_beginning_of_second if mode == :create
    {% end %}

    {% if @type.instance_vars.select { |ivar| ivar.annotation(Granite::Column) }.map(&.stringify).includes? "updated_at" %}
      @updated_at = time.to_utc.at_beginning_of_second
    {% end %}
  end

  private def __create
    set_timestamps
    columns = self.class.columns
    params = values
    {% begin %}
      {% pk = @type.instance_vars.find { |ivar| ann = ivar.annotation(Granite::Column); ann && ann[:primary] == true } %}
      {% pk_ann = pk.annotation(Granite::Column) %}
      {% auto = pk_ann && (pk_ann[:auto] == true || pk_ann[:auto] == false) ? pk_ann[:auto] : true %}
      {% raise "A primary key must be defined for #{@type.name}" unless pk %}

      {% for ivar in @type.instance_vars.reject { |t| t.type.nilable? || ["new_record", "destroyed", "granite_errors"].includes? t.name.stringify } %}
        raise "{{ivar.name}} cannot be null" if @{{ivar.id}}.nil?
      {% end %}

      {% if auto %}
        {% if pk.type.union_types.first == Int32 %}
          params.shift
          columns.shift
          @{{pk.name}} = self.class.adapter.insert(self.class.table, columns, params, {{pk.name.stringify}}).to_i
        {% elsif pk.type.union_types.first == Int64 %}
          params.shift
          columns.shift
          @{{pk.name}} = self.class.adapter.insert(self.class.table, columns, params, {{pk.name.stringify}})
        {% elsif pk.type.union_types.first == UUID %}
          @{{pk.name}} = UUID.random
          params[0] = @{{pk.name}}
          self.class.adapter.insert(self.class.table, columns, params, nil)
        {% end %}
      {% else %}
        unless {{pk.id}}
          message = "Primary key('{{pk.name}}') cannot be null"
          @granite_errors << Granite::Error.new("{{pk.name}}", message)
          raise DB::Error.new
        end
        self.class.adapter.insert(self.class.table, columns, params, nil)
      {% end %}
    {% end %}
  rescue err
    raise DB::Error.new(err.message)
  else
    @new_record = false
  end

  private def __update
    set_timestamps mode: :update
    columns = self.class.columns
    # Add in PK at end as well for the where clause
    params = values + [{{@type.instance_vars.find { |ivar| ann = ivar.annotation(Granite::Column); ann && ann[:primary] == true }.id}}]

    if created_at_index = columns.index { |c| c.name == "created_at" }
      columns.delete_at created_at_index
      params.delete_at created_at_index
    end

    self.class.adapter.update self.class.table, self.class.primary_key.name, columns, params
  rescue err
    pp err.message
    raise DB::Error.new(err.message)
  end

  private def __destroy
    self.class.adapter.delete(self.class.table, self.class.primary_key.name, {{@type.instance_vars.find { |ivar| ann = ivar.annotation(Granite::Column); ann && ann[:primary] == true }.id}})
    @destroyed = true
  rescue err
    raise DB::Error.new(err.message)
  end

  # The save method will check to see if the primary exists yet. If it does it
  # will call the update method, otherwise it will call the create method.
  # This will update the timestamps appropriately.
  def save
    (!primary_value.nil? && !new_record?) ? __update : __create
  rescue ex : DB::Error
    @granite_errors << Error.new :base, ex.message
    Granite.settings.logger.error "Save Exception: #{ex.message}"
    false
  else
    true
  end

  def save!
    save || raise Granite::RecordNotSaved.new(self.class.name, self)
  end

  # Destroy will remove this from the database.
  def destroy
    __destroy
  rescue ex : DB::Error
    Granite.settings.logger.error "Destroy Exception: #{ex.message}"
    @granite_errors << Granite::Error.new(:base, ex.message)
    false
  else
    true
  end

  def destroy!
    destroy || raise Granite::RecordNotDestroyed.new(self.class.name, self)
  end

  def update(**args)
    update(args.to_h)
  end

  def update(args : Hash(Symbol | String, DB::Any))
    set_attributes(args)

    save
  end

  def update!(**args)
    update!(args.to_h)
  end

  def update!(args : Hash(Symbol | String, DB::Any))
    set_attributes(args)

    save!
  end

  # Returns true if this object hasn't been saved yet.
  @[JSON::Field(ignore: true)]
  @[YAML::Field(ignore: true)]
  property? new_record : Bool = true

  # Returns true if this object has been destroyed.
  @[JSON::Field(ignore: true)]
  @[YAML::Field(ignore: true)]
  getter? destroyed : Bool = false

  # Returns true if the record is persisted.
  def persisted?
    !(new_record? || destroyed?)
  end
end
