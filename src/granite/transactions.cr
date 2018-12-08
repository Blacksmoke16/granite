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

      if instance.errors.any?
        raise Granite::RecordNotSaved.new(self.name, instance)
      end

      instance
    end
  end

  # macro __process_transactions

  # disable_granite_docs? def set_timestamps(*, to time = Time.now, mode = :create)
  #   {% if FIELDS.keys.stringify.includes? "created_at" %}
  #     if mode == :create
  #       @created_at = time.to_utc.at_beginning_of_second
  #     end
  #   {% end %}

  #   {% if FIELDS.keys.stringify.includes? "updated_at" %}
  #     @updated_at = time.to_utc.at_beginning_of_second
  #   {% end %}
  # end

  private def __create
    # set_timestamps
    columns = self.class.columns.dup
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
            {% raise "Failed to define #{@type.name}#save: Primary key must be defined as Int(32|64) for auto increment PKs. @[Granite::Column(primary: true)]\n\nFor natural keys set auto to false: @[Granite::Column(primary: trueauto: false)]" %}
          {% end %}
        rescue err : DB::Error
          raise err
        rescue err
          raise DB::Error.new(err.message)
        end
    {% end %}
    @new_record = false
  end

  # The save method will check to see if the primary exists yet. If it does it
  # will call the update method, otherwise it will call the create method.
  # This will update the timestamps appropriately.
  disable_granite_docs? def save
    begin
      # __before_save
      if primary_value && !new_record?
        # __before_update
        # __update
        # __after_update
      else
        # __before_create
        __create
        # __after_create
      end
      # __after_save
    rescue ex : DB::Error | Granite::Callbacks::Abort
      if message = ex.message
        Granite.settings.logger.error "Save Exception: #{message}"
      end
      return false
    end
    true
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
