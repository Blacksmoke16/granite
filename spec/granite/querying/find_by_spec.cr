require "../../spec_helper"

describe Granite::Querying do
  describe ".find_by" do
    it "finds an object with a string field" do
      Parent.clear
      name = "robinson"

      model = Parent.new
      model.name = name
      model.save

      found = Parent.find_by(name: name)
      found.not_nil!.id.should eq model.id
    end

    it "works with multiple arguments" do
      Review.clear

      Review.create(name: "review1", upvotes: 2_i64)
      Review.create(name: "review2", upvotes: 0_i64)

      expected = Review.create(name: "review3", upvotes: 10_i64)

      Review.find_by(name: "review3", upvotes: 10).not_nil!.id.should eq expected.id
    end

    it "works with reserved words" do
      ReservedWord.clear
      value = "foobar"

      model = ReservedWord.new
      model.all = value
      model.save

      found = ReservedWord.find_by(all: value)
      found.not_nil!.id.should eq model.id
    end

    it "returns nil if a record is not found" do
      Review.find_by(name: "review1", upvotes: 20).should be_nil
    end
  end

  describe ".find_by!" do
    it "finds an object with a string field" do
      Parent.clear
      name = "bar"

      model = Parent.new
      model.name = name
      model.save

      found = Parent.find_by!(name: name)
      found.id.should eq model.id
    end

    it "works with multiple arguments" do
      Review.clear

      Review.create(name: "review1", upvotes: 2_i64)
      Review.create(name: "review2", upvotes: 0_i64)

      expected = Review.create(name: "review3", upvotes: 10_i64)

      Review.find_by!(name: "review3", upvotes: 10).id.should eq expected.id
    end

    it "works with reserved words" do
      ReservedWord.clear
      value = "foo"

      model = ReservedWord.new
      model.all = value
      model.save

      found = ReservedWord.find_by!(all: value)
      found.id.should eq model.id
    end

    it "raises an exception if a record is not found" do
      expect_raises(Granite::Querying::NotFound, /No .*Review.* found where name = review1 and upvotes = 20/) { Review.find_by!(name: "review1", upvotes: 20) }
    end
  end
end
