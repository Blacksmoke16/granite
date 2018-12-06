require "./error"

# DB migration tool that prepares a table for the class
#
# ```crystal
# class User < Granite::Base
#   adapter mysql
#   field name : String
# end
#
# User.migrator.drop_and_create
# # => "DROP TABLE IF EXISTS `users`;"
# # => "CREATE TABLE `users` (id BIGSERIAL PRIMARY KEY, name VARCHAR(255));"
#
# User.migrator(table_options: "ENGINE=InnoDB DEFAULT CHARSET=utf8").create
# # => "CREATE TABLE ... ENGINE=InnoDB DEFAULT CHARSET=utf8;"
# ```
module Granite::Migrator
  class Base
    @quoted_table_name : String

    def initialize(klass, @table_options = "")
      @quoted_table_name = klass.quoted_table_name
    end

    def drop_and_create
      drop
      create
    end

    def drop
    end

    def create
    end
  end

  macro __process_migrator
    {% klass = @type.name %}
    {% adapter = "#{klass}.adapter".id %}

    disable_granite_docs? class Migrator < Granite::Migrator::Base
      def drop
        {{klass}}.exec "DROP TABLE IF EXISTS #{ @quoted_table_name };"
      end

      def create
        resolve = ->(key : String) {
          {{adapter}}.class.schema_type?(key) || raise "Migrator(#{ {{adapter}}.class.name }) doesn't support '#{key}' yet."
        }


        stmt = String.build do |s|
          s << "CREATE TABLE #{ @quoted_table_name }("

          {{@type}}.columns.each do |c|
            k = {{adapter}}.quote(c.name)
            v = if %(created_at updated_at).includes?(c.name)
                  resolve.call(c.name)
                elsif c.auto
                  resolve.call("AUTO_#{c.type}")
                else
                 resolve.call(c.type.to_s)
                 end
            s << "#{k} #{v}"
            s << " PRIMARY KEY" if c.primary == true
            s << (c.nilable && !c.primary ? " NULL" : " NOT NULL")
            s << " DEFAULT #{{{adapter}}.quote_value(c.default)}" unless c.default.nil?
            s << ','
          end

          s.chomp! 44_u8

          s << ")#{@table_options};"
        end

        {{klass}}.exec stmt
      end
    end

    disable_granite_docs? def self.migrator(**args)
      Migrator.new(self, **args)
    end
  end
end
