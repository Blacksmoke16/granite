require "./exceptions"

module Granite::Transactions
  module ClassMethods
    disable_granite_docs? def clear
      @@adapter.clear table
    end

    disable_granite_docs? def create(**args) : self
      create(args.to_h)
    end

    disable_granite_docs? def create(args : Hash(Symbol | String, DB::Any)) : self
      instance = new
      instance.set_attributes(args)
      instance.save
      instance
    end
  end

  disable_granite_docs? def set_timestamps(*, to time = Time.now, mode = :create)
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
    if primary_value.nil?
      params.shift
      columns.shift
    end
    {% begin %}
        {% pk = @type.instance_vars.find { |ivar| ann = ivar.annotation(Granite::Column); ann && ann[:primary] == true } %}
        {% pk_ann = pk.annotation(Granite::Column) %}
        {% auto = pk_ann && (pk_ann[:auto] == true || pk_ann[:auto] == false) ? pk_ann[:auto] : true %}
        {% raise "A primary key must be defined for #{@type.name}" unless pk %}

        {% if auto %}
          {% if pk.type.union_types.first == Int32 %}
            @{{pk.name}} = self.class.adapter.insert(self.class.table, columns, params, {{pk.name.stringify}}).to_i
          {% elsif pk.type.union_types.first == Int64 %}
            @{{pk.name}} = self.class.adapter.insert(self.class.table, columns, params, {{pk.name.stringify}})
          {% end %}
        {% end %}
    {% end %}
    @new_record = false
  end

  private def __update
    set_timestamps mode: :update
    columns = self.class.columns
    params = values + [{{@type.instance_vars.find { |ivar| ann = ivar.annotation(Granite::Column); ann && ann[:primary] == true }.id}}]

    self.class.adapter.update self.class.table, self.class.primary_key.name, columns, params
  rescue err
    raise DB::Error.new(err.message)
  end

  private def __destroy
    elf.class.adapter.delete(self.class.table, self.class.primary_key.name, {{@type.instance_vars.find { |ivar| ann = ivar.annotation(Granite::Column); ann && ann[:primary] == true }.id}})
    @destroyed = true
  rescue err
    raise DB::Error.new(err.message)
  end

  # The save method will check to see if the primary exists yet. If it does it
  # will call the update method, otherwise it will call the create method.
  # This will update the timestamps appropriately.
  disable_granite_docs? def save
    (primary_value && !new_record?) ? __update : __create
  rescue ex : DB::Error
    Granite.settings.logger.error "Save Exception: #{ex.message}"
    false
  else
    true
  end

  disable_granite_docs? def save!
    save || raise Granite::RecordNotSaved.new(self.class.name, self)
  end

  # Destroy will remove this from the database.
  disable_granite_docs? def destroy
    __destroy
  rescue ex : DB::Error
    if message = ex.message
      Granite.settings.logger.error "Destroy Exception: #{message}"
      # errors << Granite::Error.new(:base, message)
    end
    false
  else
    true
  end

  disable_granite_docs? def destroy!
    destroy || raise Granite::RecordNotDestroyed.new(self.class.name, self)
  end

  # Returns true if this object hasn't been saved yet.
  @[JSON::Field(ignore: true)]
  @[YAML::Field(ignore: true)]
  getter? new_record : Bool = true

  # Returns true if this object has been destroyed.
  @[JSON::Field(ignore: true)]
  @[YAML::Field(ignore: true)]
  getter? destroyed : Bool = false

  # Returns true if the record is persisted.
  disable_granite_docs? def persisted?
    !(new_record? || destroyed?)
  end
end
