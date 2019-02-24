require "../../spec_helper"

describe "UUID creation" do
  it "correctly sets a RFC4122 V4 UUID on save" do
    item = UUIDModel.new
    item.uuid.should be_nil
    item.non_pk_uuid = UUID.random

    item.save
    item.uuid.should be_a(UUID?)
    if uuid = item.uuid
      uuid.version.v4?.should be_true
      uuid.variant.rfc4122?.should be_true
    end

    item = UUIDModel.first!
    item.uuid.should be_a(UUID?)
    if uuid = item.uuid
      uuid.version.v4?.should be_true
      uuid.variant.rfc4122?.should be_true
    end

    if uuid = item.non_pk_uuid
      uuid.version.v4?.should be_true
      uuid.variant.rfc4122?.should be_true
    end
  end
end
