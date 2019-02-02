require "./error"

# DB migration tool that prepares a table for the class
#
# ```crystal
# class User < Granite::Base
#   adapter mysql
#   property name : String
# end
#
# User.migrator.drop_and_create
# # => "DROP TABLE IF EXISTS `users`;"
# # => "CREATE TABLE `users` (id BIGINT AUTO INCREMENT PRIMARY KEY, name VARCHAR(255) NOT NULL);"
#
# User.migrator(table_options: "ENGINE=InnoDB DEFAULT CHARSET=utf8").create
# # => "CREATE TABLE ... ENGINE=InnoDB DEFAULT CHARSET=utf8;"
# ```
module Granite::Migrator
  module ClassMethods
    def migrator(**args)
      MigratorBase(self).new(**args)
    end
  end

  private struct MigratorBase(Model)
    getter raw_sql : String?

    def initialize(@table_options = ""); end

    def raw_sql : String
      if stmt = @raw_sql
        stmt
      else
        build_query
      end
    end

    # Drops and recreates `self`'s table
    def drop_and_create : DB::ExecResult
      drop
      create
    end

    # Drops the `self`'s table
    def drop : DB::ExecResult
      Model.exec "DROP TABLE IF EXISTS #{Model.quoted_table_name};"
    end

    # Creates the `self`'s table
    def create : DB::ExecResult
      Model.exec raw_sql
    end

    # Builds the SQL CREATE TABLE statement for `self`
    def build_query : String
      resolve = ->(key : String) {
        Model.adapter.class.schema_type?(key) || raise "Migrator(#{Model.adapter}) doesn't support '#{key}' yet."
      }

      stmt = String.build do |s|
        s << "CREATE TABLE #{Model.quoted_table_name}("

        column_list = Model.columns

        # Add in the default id Int64 auto increment PK if no columns are set as the PK
        column_list.unshift Model.primary_key if column_list.none?(&.primary)

        column_list.each do |c|
          k = Model.adapter.quote(c.name)
          v = if %(created_at updated_at).includes?(c.name)
                resolve.call(c.name)
              elsif c.auto
                resolve.call("AUTO_#{c.type}")
              else
                resolve.call(c.type.to_s)
              end
          s << "#{k} #{v}"
          s << " PRIMARY KEY" if c.primary
          s << (c.nilable && !c.primary ? " NULL" : " NOT NULL")
          s << " DEFAULT #{Model.adapter.quote_value(c.default)}" unless c.default.nil?
          s << ','
        end

        # Remove trailing comma
        s.chomp! 44_u8

        s << ")#{@table_options};"
      end

      @raw_sql = stmt
    end
  end
end
