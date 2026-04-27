module UsersHelper
  def user_initials(user)
    return "" unless user

    if user.first_name.present? && user.last_name.present?
      "#{user.first_name[0]}#{user.last_name[0]}".upcase
    elsif user.first_name.present?
      user.first_name[0, 2].upcase
    else
      user.email_address.to_s[0, 2].upcase
    end
  end

  def user_display_name(user)
    return "" unless user

    if user.first_name.present? || user.last_name.present?
      [user.first_name, user.last_name].compact_blank.join(" ")
    else
      user.email_address
    end
  end
end
