module Admin
  class CategoriesController < AdminController
    before_action :load_category, only: %i[edit update destroy update_position]

    def index
      scope =
        if params[:q].present?
          Category.with_attached_image
                  .where("name ILIKE ?", "%#{ActiveRecord::Base.sanitize_sql_like(params[:q])}%")
                  .ordered
        else
          Category.with_attached_image.ordered
        end

      @pagy, @categories = pagy(scope, limit: DEFAULT_PER_PAGE)
    end

    def new
      @category = Category.new
    end

    def create
      @category = Category.new(category_params)

      if @category.save
        respond_to(&:turbo_stream)
      else
        render turbo_stream: turbo_stream.replace(
          "category-form",
          partial: "admin/categories/form",
          locals: { category: @category }
        ), status: :unprocessable_content
      end
    end

    def edit; end

    def update
      attrs = category_params
      new_position = attrs.delete(:position).presence&.to_i
      @reordered = false

      if @category.update(attrs)
        if new_position && new_position != @category.position
          @category.insert_at(new_position)
          @reordered = true
          @pagy, @categories = pagy(Category.with_attached_image.ordered, limit: DEFAULT_PER_PAGE)
        end
        respond_to(&:turbo_stream)
      else
        render turbo_stream: turbo_stream.replace(
          "category-form",
          partial: "admin/categories/form",
          locals: { category: @category }
        ), status: :unprocessable_content
      end
    end

    def destroy
      @category.destroy
      respond_to(&:turbo_stream)
    end

    def update_position
      position = params[:position].to_i
      return head :unprocessable_content if position < 1

      @category.insert_at(position)
      head :ok
    end

    private

    def load_category
      @category = Category.friendly.find(params[:id])
    end

    def category_params
      params.require(:category).permit(:name, :color, :image, :position)
    end
  end
end
