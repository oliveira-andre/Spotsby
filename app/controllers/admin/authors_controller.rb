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
    end

    def new
      @author = Author.new
    end

    def create
      @author = Author.new(author_params)

      if @author.save
        respond_to do |format|
          format.turbo_stream
        end
      else
        render turbo_stream: turbo_stream.update(
          "author-wizard-step",
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
  end
end
