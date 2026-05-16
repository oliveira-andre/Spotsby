class Session < ApplicationRecord
  belongs_to :user

  scope :recently_active, -> { where("last_seen_at > ?", 2.minutes.ago) }
  scope :listable_for, ->(session) {
    where("last_seen_at > ? OR id = ?", 2.minutes.ago, session&.id)
  }

  def device_label
    parts = []
    ua = user_agent.to_s

    browser =
      case ua
      when /Edg\//  then "Edge"
      when /OPR\/|Opera/ then "Opera"
      when /Chrome\//, /CriOS/ then "Chrome"
      when /Firefox\//, /FxiOS/ then "Firefox"
      when /Safari\// then "Safari"
      end

    os =
      case ua
      when /iPhone/ then "iPhone"
      when /iPad/ then "iPad"
      when /Android/ then "Android"
      when /Macintosh|Mac OS X/ then "macOS"
      when /Windows/ then "Windows"
      when /Linux/ then "Linux"
      end

    parts << browser if browser
    parts << "on #{os}" if os
    parts.join(" ").presence || "Unknown device"
  end
end
