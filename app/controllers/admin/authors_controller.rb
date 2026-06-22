module Admin
  class AuthorsController < AdminController
    before_action :load_author, only: %i[edit update destroy]

    def index
      scope = Author.with_attached_image.order(created_at: :desc)

      if params[:q].present?
        like = "%#{ActiveRecord::Base.sanitize_sql_like(params[:q])}%"
        scope = scope.where("name ILIKE :q OR description ILIKE :q", q: like)
      end

      @pagy, @authors = pagy(scope, limit: DEFAULT_PER_PAGE)
      @album_counts = Rails.cache.fetch([ "admin/album_counts", Album.count, Album.maximum(:updated_at)&.to_i ]) do
        Album.group(:author_id).count
      end
    end

    def new
      @author = Author.new
    end

    # Inline author creation from the song form's "Featured artists" picker.
    # Responds with turbo_stream so the wizard/song modal stays open.
    def quick_create
      @author = Author.new(quick_create_params)
      if @author.save
        render :quick_create, status: :ok
      else
        render turbo_stream: turbo_stream.update(
          "author-quick-add-error",
          partial: "admin/authors/quick_add_error",
          locals: { author: @author }
        ), status: :unprocessable_content
      end
    end

    def create
      @author = Author.new(author_params)

      if @author.save
        respond_to do |format|
          format.turbo_stream
        end
      else
        render turbo_stream: turbo_stream.update(
          "wizard-step",
          partial: "admin/authors/wizard_author",
          locals: { author: @author }
        ), status: :unprocessable_content
      end
    end

    def edit; end

    def update
      if @author.update(author_params)
        respond_to do |format|
          format.turbo_stream
        end
      else
        render turbo_stream: turbo_stream.replace(
          "author-form",
          partial: "admin/authors/form",
          locals: { author: @author }
        ), status: :unprocessable_content
      end
    end

    def destroy
      @author.destroy
      respond_to do |format|
        format.turbo_stream
      end
    end

    private

    def load_author
      @author = Author.friendly.find(params[:id])
    end

    def author_params
      params.require(:author).permit(:name, :description, :image, :user_id)
    end

    def quick_create_params
      params.require(:author).permit(:name)
    end
  end
end
