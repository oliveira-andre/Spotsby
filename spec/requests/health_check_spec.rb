require "rails_helper"

RSpec.describe "GET /health_check", type: :request do
  def stub_checks(results)
    allow_any_instance_of(HealthCheckService).to receive(:call).and_return(results)
  end

  it "answers 200 with every check when all pass" do
    stub_checks(app: true, redis: true)
    get "/health_check"

    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq("application/json")
    expect(response.parsed_body).to eq("app" => true, "redis" => true)
  end

  it "answers 503 when a check fails, still naming every check" do
    stub_checks(app: true, redis: false)
    get "/health_check"

    expect(response).to have_http_status(:service_unavailable)
    expect(response.parsed_body).to eq("app" => true, "redis" => false)
  end

  it "answers JSON even when the service raises" do
    allow_any_instance_of(HealthCheckService).to receive(:call).and_raise("boom")
    get "/health_check", headers: { "Accept" => "text/html" }

    expect(response).to have_http_status(:service_unavailable)
    expect(response.parsed_body).to eq("app" => false)
  end
end
