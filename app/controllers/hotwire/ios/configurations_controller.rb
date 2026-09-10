module Hotwire
  module Ios
    class ConfigurationsController < ApplicationController
      skip_before_action :require_authentication

      def v1
        render json: {
          settings: {},
          rules: [
            {
              patterns: [ ".*" ],
              properties: build_properties(context: "default", pull_to_refresh_enabled: true)
            },
            {
              patterns: [ "/new$", "/edit$" ],
              properties: build_properties(context: "modal", pull_to_refresh_enabled: false)
            },
            {
              patterns: [ "^/session", "^/registration" ],
              properties: build_properties(context: "default", pull_to_refresh_enabled: false, view_controller: "auth")
            },
            {
              # The Create tab presents this as a sheet instead of navigating to a page.
              patterns: [ "^/playlists/create_options" ],
              properties: build_properties(context: "modal", pull_to_refresh_enabled: false)
            },
            {
              # The big player has full controls; the native mini player would only duplicate them.
              patterns: [ "^/players/" ],
              properties: build_properties(hides_player_accessory: true)
            },
            # {
            #   patterns: [todos_path],
            #   properties: { context: "default", view_controller: "hello" }
            # },
            {
              patterns: [refresh_app_path],
              properties: { presentation: "refresh", view_controller: "refresh_app" }
            }
          ]
        }
      end

      private

      def build_properties(options = {})
        options
      end
    end
  end
end