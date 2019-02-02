require "../../spec_helper"

describe "#new" do
  it "works when the primary is defined as `auto: true`" do
    Parent.new
  end

  it "works when the primary is defined as `auto: false`" do
    Kvs.new
  end
end

describe "#new(primary_key: value)" do
  pending "does not set the value when the primary is defined as `auto: true`" do
    Parent.new(id: 1).id.should be_nil
  end

  it "sets the value when the primary is defined as `auto: false`" do
    Kvs.new(k: "foo").k.should eq("foo")
    Kvs.new(k: "foo", v: "v").k.should eq("foo")
  end
end
