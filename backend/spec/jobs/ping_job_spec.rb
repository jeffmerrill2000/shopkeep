require "rails_helper"

RSpec.describe PingJob do
  it "writes a timestamp through the cache" do
    memory = ActiveSupport::Cache::MemoryStore.new
    allow(Rails).to receive(:cache).and_return(memory)

    described_class.perform_now

    expect(memory.read("shopkeep:last_ping")).to be_present
  end
end
