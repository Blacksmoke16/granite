require "./exceptions"

module Granite::Transactions
  module ClassMethods
    disable_granite_docs? def clear
      @@adapter.clear @@table_name
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

    disable_granite_docs? def create!(**args) : self
      create!(args.to_h)
    end

    disable_granite_docs? def create!(args : Hash(Symbol | String, DB::Any)) : self
      instance = create(args)
      # raise Granite::RecordNotSaved.new(self.name, instance) if instance.errors.any?
      instance
    end
  end

  disable_granite_docs? def set_timestamps(*, to time = Time.now, mode = :create)
    {% if @type.instance_vars.select { |ivar| ivar.annotation(Granite::Column) }.map(&.stringify).includes? "created_at" %}
      if mode == :create
        @created_at = time.to_utc.at_beginning_of_second
      end
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
        begin
          {% pk = @type.instance_vars.find { |ivar| ann = ivar.annotation(Granite::Column); ann && ann[:primary] == true } %}

          {% if pk %}
            {% pk_ann = pk.annotation(Granite::Column) %}
            {% primary_name = pk.name %}
            {% primary_type = pk.type %}
            {% primary_auto = pk_ann && pk_ann[:auto] ? pk_ann[:auto] : true %}

            {% if primary_type.union? ? primary_type.union_types.includes?(Int32) : primary_type == Int32 && primary_auto == true %}
              @{{primary_name}} = @@adapter.insert(@@table_name, columns, params, lastval: "{{primary_name}}").to_i32
            {% elsif primary_type.union? ? primary_type.union_types.includes?(Int64) : primary_type == Int64 && primary_auto == true %}
              @{{primary_name}} = @@adapter.insert(@@table_name, columns, params, lastval: "{{primary_name}}")
            {% elsif primary_type.union? ? primary_type.union_types.includes?(UUID) : primary_type == UUID && primary_auto == true %}
              _uuid = UUID.random
              @{{primary_name}} = _uuid
              params.unshift _uuid
              columns.unshift self.class.primary_key
              @@adapter.insert(@@table_name, columns, params, lastval: nil)
            {% end %}
          {% else %}
            {% raise "Failed to define #{@type.name}#save: Primary key must be defined as Int(32|64) for auto increment PKs. @[Granite::Column(primary: true)]\n\nFor natural keys set auto to false: @[Granite::Column(primary: true, auto: false)]" %}
          {% end %}
        rescue err : DB::Error
          raise err
        rescue err
          raise DB::Error.new(err.message)
        end
    {% end %}
    @new_record = false
  end

  private def __update
    set_timestamps mode: :update
    columns = self.class.columns
    params = values + [{{@type.instance_vars.find { |ivar| ann = ivar.annotation(Granite::Column); ann && ann[:primary] == true }.id}}]

    begin
      @@adapter.update @@table_name, self.class.primary_key.name, columns, params
    rescue err
      raise DB::Error.new(err.message)
    end
  end

  private def __destroy
    @@adapter.delete(@@table_name, self.class.primary_key.name, {{@type.instance_vars.find { |ivar| ann = ivar.annotation(Granite::Column); ann && ann[:primary] == true }.id}})
    @destroyed = true
  end

  # The save method will check to see if the primary exists yet. If it does it
  # will call the update method, otherwise it will call the create method.
  # This will update the timestamps appropriately.
  disable_granite_docs? def save
    begin
      if primary_value && !new_record?
        __update
      else
        __create
      end
    rescue ex : DB::Error
      if message = ex.message
        Granite.settings.logger.error "Save Exception: #{message}"
        # errors << Granite::Error.new(:base, message)
      end
      return false
    end
    true
  end

  disable_granite_docs? def save!
    save || raise Granite::RecordNotSaved.new(self.class.name, self)
  end

  disable_granite_docs? def update(**args)
    update(args.to_h)
  end

  disable_granite_docs? def update(args : Hash(Symbol | String, DB::Any))
    set_attributes(args)

    save
  end

  disable_granite_docs? def update!(**args)
    update!(args.to_h)
  end

  disable_granite_docs? def update!(args : Hash(Symbol | String, DB::Any))
    set_attributes(args)

    save!
  end

  # Destroy will remove this from the database.
  disable_granite_docs? def destroy
    begin
      __destroy
    rescue ex : DB::Error
      if message = ex.message
        Granite.settings.logger.error "Destroy Exception: #{message}"
        # errors << Granite::Error.new(:base, message)
      end
      return false
    end
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
