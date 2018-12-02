require "yaml"
require "db"

module Granite
  DATETIME_FORMAT = "%F %X%z"
  annotation Column; end
  annotation PrimaryKey; end
end

require "./granite/base"
