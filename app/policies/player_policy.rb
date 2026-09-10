# frozen_string_literal: true

# Headless policy for the playback actions (`authorize :player, :next?`).
# Playback needs a signed-in, non-blocked user; it has no record of its own.
class PlayerPolicy < ApplicationPolicy
  def show?
    listener?
  end

  def next?
    listener?
  end

  def previous?
    listener?
  end

  def toggle_random?
    listener?
  end

  private

  def listener?
    user.present? && !user.blocked?
  end
end
