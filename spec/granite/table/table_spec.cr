require "../../spec_helper"

describe Granite::Table do
  describe ".table" do
    it "sets the table name to name specified" do
      CustomSongThread.table.should eq "custom_table_name"
    end

    it "sets the table name based on class name if not specified" do
      SongThread.table.should eq "song_threads"
    end
  end

  describe ".adapter" do
    it "returns the model's adapter" do
      ["sqlite", "pg", "mysql"].should contain CustomSongThread.adapter.name
    end
  end
end
