require "../../spec_helper"

describe Granite::RecordNotDestroyed do
  pending "should have a message" do
    parent = Parent.new
    parent.save

    Granite::RecordNotDestroyed
      .new(Parent.name, parent)
      .message
      .should eq("Could not destroy Parent")
  end

  pending "should have a model" do
    parent = Parent.new
    parent.save

    Granite::RecordNotDestroyed
      .new(Parent.name, parent)
      .model
      .should eq(parent)
  end
end
