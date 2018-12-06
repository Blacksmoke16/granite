class Granite::Base
  def self.drop_and_create
  end
end

require "uuid"

{% begin %}
  {% adapter_literal = env("CURRENT_ADAPTER").id %}

  class Parent < Granite::Base
    adapter {{ adapter_literal }}
    table_name parents

    @[Granite::Column(primary: true)]
    property id : Int64?

    @[Granite::Column]
    property name : String

    # @[Granite::Column]
    property created_at : Time?

    # @[Granite::Column]
    property updated_at : Time?

    # has_many :students, class_name: Student
  end

  # class Teacher < Granite::Base
  #   primary id : Int64
  #   adapter {{ adapter_literal }}
  #   table_name teachers

  #   field name : String

  #   has_many :klasses, class_name: Klass
  # end

  # class Student < Granite::Base
  #   primary id : Int64
  #   adapter {{ adapter_literal }}
  #   table_name students

  #   field name : String

  #   has_many :enrollments, class_name: Enrollment
  #   has_many :klasses, class_name: Klass, through: :enrollments
  # end

  # class Klass < Granite::Base
  #   primary id : Int64
  #   adapter {{ adapter_literal }}
  #   table_name klasses
  #   field name : String

  #   belongs_to teacher : Teacher

  #   has_many :enrollments, class_name: Enrollment
  #   has_many :students, class_name: Student, through: :enrollments
  # end

  # class Enrollment < Granite::Base
  #   primary id : Int64
  #   adapter {{ adapter_literal }}
  #   table_name enrollments

  #   belongs_to :student
  #   belongs_to :klass
  # end

  class School < Granite::Base
    adapter {{ adapter_literal }}

    table_name schools

    @[Granite::Column(primary: true)]
    property custom_id : Int64?

    @[Granite::Column]
    property name : String
  end

  # class User < Granite::Base
  #   adapter {{ adapter_literal }}
  #   primary id : Int64
  #   field email : String

  #   has_one :profile

  #   table_name users
  # end

  # class Character < Granite::Base
  #   adapter {{ adapter_literal }}
  #   table_name characters

  #   primary character_id : Int32
  #   field! name : String
  # end

  # class Courier < Granite::Base
  #   adapter {{ adapter_literal }}
  #   table_name couriers

  #   primary courier_id : Int32, auto: false
  #   field! issuer_id : Int32

  #   belongs_to service : CourierService, primary_key: "owner_id"
  #   has_one issuer : Character, primary_key: "issuer_id", foreign_key: "character_id"
  # end

  # class CourierService < Granite::Base
  #   adapter {{ adapter_literal }}
  #   table_name services

  #   has_many :couriers, class_name: Courier, foreign_key: "service_id"

  #   primary owner_id : Int64, auto: false
  #   field! name : String
  # end

  # class Profile < Granite::Base
  #   adapter {{ adapter_literal }}
  #   primary id : Int64
  #   field name : String

  #   belongs_to :user

  #   table_name profiles
  # end

  class Nation::County < Granite::Base
    adapter {{ adapter_literal }}
    table_name nation_counties

    @[Granite::Column(primary: true)]
    property id : Int64?

    @[Granite::Column]
    property name : String
  end

  class Review < Granite::Base
    adapter {{ adapter_literal }}
    table_name reviews

    @[Granite::Column(primary: true)]
    property id : Int64?

    @[Granite::Column]
    property name : String

    @[Granite::Column]
    property downvotes : Int32?

    @[Granite::Column]
    property upvotes : Int64?

    @[Granite::Column]
    property sentiment : Float32?

    @[Granite::Column]
    property interest : Float64?

    @[Granite::Column]
    property published : Bool

    # @[Granite::Column]
    property created_at : Time?
  end

  # class Empty < Granite::Base
  #   adapter {{ adapter_literal }}
  #   table_name empties
  #   primary id : Int64
  # end

  class ReservedWord < Granite::Base
    adapter {{ adapter_literal }}
    table_name "select"

    @[Granite::Column(primary: true)]
    property id : Int64?

    @[Granite::Column]
    property all : String
  end

  # class Callback < Granite::Base
  #   adapter {{ adapter_literal }}
  #   table_name callbacks
  #   primary id : Int64
  #   field name : String

  #   property history : IO::Memory = IO::Memory.new

  #   {% for name in Granite::Callbacks::CALLBACK_NAMES %}
  #     {{name.id}} _{{name.id}}
  #     private def _{{name.id}}
  #       history << "{{name.id}}\n"
  #     end
  #   {% end %}
  # end

  # class CallbackWithAbort < Granite::Base
  #   adapter {{ adapter_literal }}
  #   table_name callbacks_with_abort
  #   primary abort_at : String, auto: false
  #   field do_abort : Bool
  #   field name : String

  #   property history : IO::Memory = IO::Memory.new

  #   {% for name in Granite::Callbacks::CALLBACK_NAMES %}
  #     {{name.id}} do
  #       abort! if do_abort && abort_at == "{{name.id}}"
  #       history << "{{name.id}}\n"
  #     end
  #   {% end %}
  # end

  # class Kvs < Granite::Base
  #   adapter {{ adapter_literal }}
  #   table_name kvs
  #   primary k : String, auto: false
  #   field v : String
  # end

  # class Person < Granite::Base
  #   adapter {{ adapter_literal }}
  #   table_name people

  #   field name : String
  # end

  # class Company < Granite::Base
  #   adapter {{ adapter_literal }}
  #   table_name companies

  #   primary id : Int32
  #   field name : String
  # end

  # class Book < Granite::Base
  #   adapter {{ adapter_literal }}
  #   table_name books
  #   has_many :book_reviews, class_name: BookReview
  #   belongs_to author : Person
  #   belongs_to publisher : Company, foreign_key: publisher_id : Int32, json_options: {ignore: true}, yaml_options: {ignore: true}

  #   primary id : Int32
  #   field name : String
  # end

  # class BookReview < Granite::Base
  #   adapter {{ adapter_literal }}
  #   table_name book_reviews
  #   belongs_to book : Book, foreign_key: book_id : Int32

  #   primary id : Int32
  #   field body : String
  # end

  # class Item < Granite::Base
  #   adapter {{ adapter_literal }}
  #   table_name items

  #   primary item_id : String, auto: false
  #   field item_name : String

  #   before_create :generate_uuid

  #   def generate_uuid
  #     @item_id = UUID.random.to_s
  #   end
  # end

  # class NonAutoDefaultPK < Granite::Base
  #   adapter {{ adapter_literal }}
  #   table_name non_auto_default_pk

  #   primary id : Int64, auto: false
  #   field name : String
  # end

  # class NonAutoCustomPK < Granite::Base
  #   adapter {{ adapter_literal }}
  #   table_name non_auto_custom_pk

  #   primary custom_id : Int64, auto: false
  #   field name : String
  # end

  # class Article < Granite::Base
  #   adapter {{ adapter_literal }}
  #   table_name articles

  #   primary id : Int64
  #   field articlebody : String
  # end

  # class Comment < Granite::Base
  #   adapter {{ adapter_literal }}
  #   table_name comments

  #   primary id : Int64
  #   field commentbody : String
  #   field articleid : Int64
  # end

  # class SongThread < Granite::Base
  #   adapter {{ env("CURRENT_ADAPTER").id }}
  #   table_name song_threads
  #   field name : String
  # end

  # class CustomSongThread < Granite::Base
  #   adapter {{ env("CURRENT_ADAPTER").id }}
  #   table_name custom_table_name
  #   primary custom_primary_key : Int64
  #   field name : String
  # end

  # @[JSON::Serializable::Options(emit_nulls: true)]
  # @[YAML::Serializable::Options(emit_nulls: true)]
  # class TodoEmitNull < Granite::Base
  #   adapter {{ adapter_literal }}
  #   table_name todos

  #   field name : String
  #   field priority : Int32
  #   timestamps
  # end

  # class Todo < Granite::Base
  #   adapter {{ adapter_literal }}
  #   table_name todos

  #   field name : String
  #   field priority : Int32
  #   timestamps
  # end

  # class AfterInit < Granite::Base
  #   adapter {{ adapter_literal }}
  #   table_name after_json_init

  #   field name : String
  #   field priority : Int32

  #   def after_initialize
  #     @priority = 1000
  #   end
  # end

  # class ArticleViewModel < Granite::Base
  #   adapter {{ adapter_literal }}
  #   table_name article_views

  #   field articlebody : String
  #   field commentbody : String

  #   select_statement <<-SQL
  #     SELECT articles.id, articles.articlebody, comments.commentbody FROM articles JOIN comments ON comments.articleid = articles.id
  #   SQL
  # end

  # # Only PG supports array types
  # {% if env("CURRENT_ENV") == "pg" %}
  #   class ArrayModel < Granite::Base
  #     adapter {{ adapter_literal }}
  #     table_name array_models

  #     primary id : Int32
  #     field str_array : Array(String)
  #     field i16_array : Array(Int16)
  #     field i32_array : Array(Int32)
  #     field i64_array : Array(Int64)
  #     field f32_array : Array(Float32)
  #     field f64_array : Array(Float64)
  #     field bool_array : Array(Bool)
  #   end
  #   ArrayModel.migrator.drop_and_create
  # {% end %}

  # class UUIDModel < Granite::Base
  #   adapter {{ adapter_literal }}
  #   table_name uuids

  #   primary uuid : String, auto: :uuid
  # end

  # class TodoJsonOptions < Granite::Base
  #   adapter {{ adapter_literal }}
  #   table_name todos_json

  #   field name : String, json_options: {key: "task_name"}
  #   field priority : Int32, json_options: {ignore: true}
  #   field updated_at : Time, json_options: {ignore: true}
  #   field created_at : Time, json_options: {key: "posted"}
  # end

  # class TodoYamlOptions < Granite::Base
  #   adapter {{ adapter_literal }}
  #   table_name todos_yaml

  #   field name : String, yaml_options: {key: "task_name"}
  #   field priority : Int32, yaml_options: {ignore: true}
  #   field updated_at : Time, yaml_options: {ignore: true}
  #   field created_at : Time, yaml_options: {key: "posted"}
  # end

  private def setup_teardown

  Parent.migrator.drop_and_create
  # Teacher.migrator.drop_and_create
  # Student.migrator.drop_and_create
  # Klass.migrator.drop_and_create
  # Enrollment.migrator.drop_and_create
  School.migrator.drop_and_create
  # User.migrator.drop_and_create
  # Profile.migrator.drop_and_create
  Nation::County.migrator.drop_and_create
  Review.migrator.drop_and_create
  # Empty.migrator.drop_and_create
  ReservedWord.migrator.drop_and_create
  # Callback.migrator.drop_and_create
  # CallbackWithAbort.migrator.drop_and_create
  # Kvs.migrator.drop_and_create
  # Person.migrator.drop_and_create
  # Company.migrator.drop_and_create
  # Book.migrator.drop_and_create
  # BookReview.migrator.drop_and_create
  # Item.migrator.drop_and_create
  # NonAutoDefaultPK.migrator.drop_and_create
  # NonAutoCustomPK.migrator.drop_and_create
  # Article.migrator.drop_and_create
  # Comment.migrator.drop_and_create
  # Todo.migrator.drop_and_create
  # TodoEmitNull.migrator.drop_and_create
  # AfterInit.migrator.drop_and_create
  # SongThread.migrator.drop_and_create
  # CustomSongThread.migrator.drop_and_create
  # UUIDModel.migrator.drop_and_create
  # TodoJsonOptions.migrator.drop_and_create
  # TodoYamlOptions.migrator.drop_and_create
  # Character.migrator.drop_and_create
  # Courier.migrator.drop_and_create
  # CourierService.migrator.drop_and_create
end
{% end %}
