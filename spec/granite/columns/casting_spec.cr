require "../../spec_helper"

describe "#casting_to_fields" do
  it "compiles with empty fields" do
    model = Empty.new
    model.should_not be_nil
  end

  it "types the columns correctly" do
    model = Parent.new
    model.name = "Jim"

    model.id.should be_a Int64?
    model.name.should be_a String
  end
end
