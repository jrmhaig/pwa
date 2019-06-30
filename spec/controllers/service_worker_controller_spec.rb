require 'rails_helper'

RSpec.describe ServiceWorkerController, type: :controller do

  describe "GET #service_worker" do
    it "returns http success" do
      get :service_worker
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET #manifest" do
    it "returns http success" do
      get :manifest
      expect(response).to have_http_status(:success)
    end
  end

end
