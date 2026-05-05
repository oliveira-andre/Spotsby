require 'rails_helper'

RSpec.describe CategoriesController, type: :request do
  let(:user) { create(:user) }
  let(:category) { create(:category) }

  context 'when not authenticated' do
    it 'redirects to login' do
      get category_path(category)
      expect(response).to redirect_to(new_session_path)
    end
  end

  context 'when authenticated' do
    before { sign_in(user) }

    describe 'GET /categories/:id' do
      it 'renders the category' do
        create(:album, category: category)
        get category_path(category)
        expect(response).to have_http_status(:ok)
      end

      it 'finds by slug' do
        get category_path(category.slug)
        expect(response).to have_http_status(:ok)
      end
    end
  end
end
