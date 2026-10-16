require "rails_helper"

RSpec.describe "OpenAPI route coverage" do
  it "documents every /api route" do
    document = YAML.safe_load_file(Rails.root.join("openapi/v1/swagger.yaml"), permitted_classes: [ Symbol ], aliases: true)
    documented = document.fetch("paths").keys.sort
    routed = Rails.application.routes.routes.filter_map { |route|
      path = route.path.spec.to_s
      next unless path.start_with?("/api/")

      path.delete_suffix("(.:format)").gsub(/:(\w+)/, "{\\1}")
    }.uniq.sort

    expect(documented).to eq(routed)
  end
end
