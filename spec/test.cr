# require "pg"
require "mysql"
require "uuid"

# Granite::Adapters << Granite::Adapter::Pg.new({name: "pg", url: "postgres://postgres:@localhost"})
Granite::Adapters << Granite::Adapter::Mysql.new({name: "mysql", url: "mysql://user:pass@localhost:3306/test"})
Granite.settings.logger = Logger.new STDOUT

require "../src/granite"
# require "../src/adapter/pg"
require "../src/adapter/mysql"

class Parent < Granite::Base
  adapter mysql
  table_name "par$1ents"

  @[Granite::Column(primary: true)]
  property id : Int64?

  @[Granite::Column]
  property age : Int32

  validate :age, "can't be nil" do |parent|
    parent.age >= 0
  end
end

# Parent.migrator.drop_and_create

# p = Parent.new
# p.age = 11
# p.save

p = Parent.first!

p.update(age: 123)

# class Kvs < Granite::Base
#   adapter pg
#   table_name kvs

#   @[Granite::Column(primary: true)]
#   property k : String?

#   @[Granite::Column]
#   property v : String
# end

# puts Kvs.migrator.drop_and_create

# Parent.clear
# p = Parent.new
# p.data = JSON.parse %({"name":"Joe"})
# p.numbers = [1, 2, 3]
# p.save

# p = Parent.first!
# pp p

# Parent.clear
# model_ids = (0...10).map do |i|
#   Parent.new(id: i.to_i64, name: "model_#{i}").tap(&.save)
# end.map(&.id)

#
