module Fastlane
  module Actions
    module SharedValues
      BALTO_APPLICATION_URL = :BALTO_APPLICATION_URL
      BALTO_RELEASE_NOTE = :BALTO_RELEASE_NOTE
      BALTO_NUMBERING = :BALTO_NUMBERING
      BALTO_APP_IDENTIFIER = :BALTO_APP_IDENTIFIER
    end

    class BaltoAction < Action
      def self.run(params)
        cmd = "curl"
        cmd << " -s" # To get response only (without progress)
        cmd << " -F project_token=#{params[:project_token]}"
        cmd << " -F user_token=#{params[:user_token]}"
        cmd << " -F package=@#{params[:package]}"
        cmd << " -F release_note='#{params[:release_note]}'" if params[:release_note]
        cmd << " https://balto-api.herokuapp.com/api/v2/builds/upload"

        UI.message ""
        UI.message Terminal::Table.new(
          title: "Balto".green,
          headings: ["Option", "Value"],
          rows: params.values
        )
        UI.message ""

        UI.message "Start running"

        response = sh(cmd)

        json = JSON.parse(response)
        Actions.lane_context[SharedValues::BALTO_APPLICATION_URL] = json["application_url"]
        Actions.lane_context[SharedValues::BALTO_RELEASE_NOTE] = json["release_note"]
        Actions.lane_context[SharedValues::BALTO_NUMBERING] = json["numbering"]
        Actions.lane_context[SharedValues::BALTO_APP_IDENTIFIER] = json["app_identifier"]

        UI.success "Completed"
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Deploy package to Balto"
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :project_token,
                                       env_name: "FL_BALTO_PROJECT_TOKEN",
                                       description: "Balto project token",
                                       verify_block: proc do |value|
                                          UI.user_error!("No project token for BaltoAction given, pass using `project_token: 'token'`") unless (value and not value.empty?)
                                       end),
          FastlaneCore::ConfigItem.new(key: :user_token,
                                       env_name: "FL_BALTO_USER_TOKEN",
                                       description: "Balto user token",
                                       verify_block: proc do |value|
                                          UI.user_error!("No user token for BaltoAction given, pass using `user_token: 'token'`") unless (value and not value.empty?)
                                       end),
          FastlaneCore::ConfigItem.new(key: :package,
                                       env_name: "FL_BALTO_PACKAGE",
                                       description: "Package path to upload to Balto",
                                       verify_block: proc do |value|
                                          UI.user_error!("Couldn't find file at path '#{value}'") unless File.exist?(value)
                                       end),
          FastlaneCore::ConfigItem.new(key: :release_note,
                                       env_name: "FL_BALTO_RELEASE_NOTE",
                                       description: "Balto release note",
                                       optional: true)
        ]
      end

      def self.output
        [
          ['BALTO_APPLICATION_URL', 'URL for installing the deployed package'],
          ['BALTO_RELEASE_NOTE',    'Release note'],
          ['BALTO_NUMBERING',       'Numbering for the package created by Balto'],
          ['BALTO_APP_IDENTIFIER',  'App bundle identifier']
        ]
      end

      def self.return_value
      end

      def self.authors
        ["thedoritos"]
      end

      def self.is_supported?(platform)
        [:ios, :android].include?(platform)
      end
    end
  end
end
