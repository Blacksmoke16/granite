describe "#casting_to_fields" do
  it "compiles with empty fields" do
    model = Empty.new
    model.should_not be_nil
  end
end
