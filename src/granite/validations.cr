module Granite::Validations
  @[JSON::Field(ignore: true)]
  @[YAML::Field(ignore: true)]
  getter granite_errors = [] of Error
end
