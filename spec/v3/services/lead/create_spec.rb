describe Travis::API::V3::Services::Lead::Create, set_app: true do
  let(:user) { Factory(:user) }
  let(:token) { Travis::Api::App::AccessToken.create(user: user, app_id: 1) }
  let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}" }}
  let(:endpoint) { "/v3/lead" }
  let(:parsed_body) { JSON.load(body) }
  let(:full_options) {{
    "name" => "Test Name",
    "email" => "test@email.example.com",
    "team_size" => "123",
    "phone" => "+1 123-456-7890",
    "message" => "Interested in CI",
    "utm_source" => "Custom Source"
  }}
  let(:options) { full_options }
  let(:expected_lead_data) {{
    "@type"           => "lead",
    "@representation" => "standard",
    "id"              => "lead_12345",
    "name"            => options['name'],
    "status_label"    => "Potential",
    "contacts"        => [{
      "display_name" => options['name'],
      "name" => options['name'],
      "phones" => [{ "type" => "office", "phone" => options['phone'] }],
      "emails" => [{ "type" => "office", "email" => options['email'] }]
    }],

    "custom"          => {
      "utm_source" => options['utm_source'],
      "team_size"  => options['team_size'],
    }
  }}

  let(:close_url) { "https://api.close.com/api/v1/" }
  let(:close_lead_url) { "#{close_url}lead/" }
  let(:stubbed_response_status) { 200 }
  let(:stubbed_response_body) { JSON.dump(expected_lead_data) }
  let(:stubbed_response_headers) {{ content_type: 'application/json' }}
  let!(:stubbed_request) do
    stub_request(:post, close_lead_url).to_return(
      status: stubbed_response_status,
      body: stubbed_response_body,
      headers: stubbed_response_headers
    )
  end

  let(:close_note_url) { "#{close_url}activity/note/" }
  let!(:stubbed_note_request) do
    stub_request(:post, close_note_url).to_return(
      status: stubbed_response_status,
      body: JSON.dump({ "note" => options['message'] }),
      headers: stubbed_response_headers
    )
  end

  subject(:response) { post(endpoint, options, headers) }

  it 'sends a contact request' do
    expect(response.status).to eq(200)
    response_data = JSON.parse(response.body)
    expect(response_data).to eq(expected_lead_data)
  end

  context 'when name is missing' do
    let(:options) {{
      "email" => full_options['email'],
      "team_size" => full_options['team_size'],
      "phone" => full_options['phone'],
      "message" => full_options['message'],
      "utm_source" => full_options['utm_source']
    }}
    let(:expected_lead_data) {{
      "@type"         => "error",
      "error_type"    => "wrong_params",
      "error_message" => "missing name",
    }}

    it 'rejects the request' do
      expect(response.status).to eq(400)
      response_data = JSON.parse(response.body)
      expect(response_data).to eq(expected_lead_data)
      expect(stubbed_request).to_not have_been_made
      expect(stubbed_note_request).to_not have_been_made
    end
  end

  context 'when message is missing' do
    let(:options) {{
      "name" => full_options['name'],
      "email" => full_options['email'],
      "team_size" => full_options['team_size'],
      "phone" => full_options['phone'],
      "utm_source" => full_options['utm_source']
    }}
    let(:expected_lead_data) {{
      "@type"         => "error",
      "error_type"    => "wrong_params",
      "error_message" => "missing message",
    }}

    it 'rejects the request' do
      expect(response.status).to eq(400)
      response_data = JSON.parse(response.body)
      expect(response_data).to eq(expected_lead_data)
      expect(stubbed_request).to_not have_been_made
      expect(stubbed_note_request).to_not have_been_made
    end
  end

  context 'when email is missing' do
    let(:options) {{
      "name" => full_options['name'],
      "team_size" => full_options['team_size'],
      "phone" => full_options['phone'],
      "message" => full_options['message'],
      "utm_source" => full_options['utm_source']
    }}
    let(:expected_lead_data) {{
      "@type"         => "error",
      "error_type"    => "wrong_params",
      "error_message" => "invalid email",
    }}

    it 'rejects the request' do
      expect(response.status).to eq(400)
      response_data = JSON.parse(response.body)
      expect(response_data).to eq(expected_lead_data)
      expect(stubbed_request).to_not have_been_made
      expect(stubbed_note_request).to_not have_been_made
    end
  end

  context 'when email is invalid' do
    let(:options) {{
      "name" => full_options['name'],
      "email" => "incorrect-email",
      "team_size" => full_options['team_size'],
      "phone" => full_options['phone'],
      "message" => full_options['message'],
      "utm_source" => full_options['utm_source']
    }}
    let(:expected_lead_data) {{
      "@type"         => "error",
      "error_type"    => "wrong_params",
      "error_message" => "invalid email",
    }}

    it 'rejects the request' do
      expect(response.status).to eq(400)
      response_data = JSON.parse(response.body)
      expect(response_data).to eq(expected_lead_data)
      expect(stubbed_request).to_not have_been_made
      expect(stubbed_note_request).to_not have_been_made
    end
  end
end
