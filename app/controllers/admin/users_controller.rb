module Admin
  class UsersController < AdminController
    before_action :load_user, only: %i[edit update destroy]

    def index
      scope = User.with_attached_avatar.order(created_at: :desc, id: :desc)

      if params[:q].present?
        like = "%#{ActiveRecord::Base.sanitize_sql_like(params[:q])}%"
        scope = scope.where(
          "email_address ILIKE :q OR first_name ILIKE :q OR last_name ILIKE :q",
          q: like
        )
      end

      @pagy, @users = pagy(scope, limit: DEFAULT_PER_PAGE)
    end

    def new
      @user = User.new
    end

    def create
      @user = User.new(user_params)

      if @user.save
        respond_to do |format|
          format.turbo_stream
        end
      else
        render turbo_stream: turbo_stream.replace(
          "user-form",
          partial: "admin/users/form",
          locals: { user: @user }
        ), status: :unprocessable_content
      end
    end

    def edit; end

    def update
      if @user.update(user_params)
        respond_to do |format|
          format.turbo_stream
        end
      else
        render turbo_stream: turbo_stream.replace(
          "user-form",
          partial: "admin/users/form",
          locals: { user: @user }
        ), status: :unprocessable_content
      end
    end

    def destroy
      return head :forbidden if @user == current_user

      @user.destroy
      respond_to do |format|
        format.turbo_stream
      end
    end

    private

    def load_user
      @user = User.find(params[:id])
    end

    def user_params
      attrs = params.require(:user).permit(
        :first_name, :last_name, :email_address, :birthdate,
        :status, :avatar, :password, :password_confirmation
      )
      attrs.delete(:password) if attrs[:password].blank?
      attrs.delete(:password_confirmation) if attrs[:password_confirmation].blank?
      attrs
    end
  end
end
