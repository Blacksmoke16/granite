require "yaml"
require "db"

module Granite
  DATETIME_FORMAT = "%F %X%z"
  annotation Column; end
  annotation Callback; end
  annotation Model; end
end

require "./granite/base"
