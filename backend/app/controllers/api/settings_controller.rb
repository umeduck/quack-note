module Api
  class SettingsController < ::ApplicationController
    include JwtAuthenticatable

    before_action :set_repository

    # GET /api/settings
    # ユーザー設定を取得
    def show
      settings = @repository.find_by_user_id(current_user_id)

      if settings
        render json: {
          user_id: settings['user_id'],
          meeting_title: settings['meeting_title'],
          auto_delete_days: settings['auto_delete_days'],
          slack_webhook_url: settings['slack_webhook_url'],
          created_at: settings['created_at'],
          updated_at: settings['updated_at']
        }, status: :ok
      else
        # 設定がない場合はデフォルト値を返す
        render json: {
          user_id: current_user_id,
          meeting_title: nil,
          auto_delete_days: nil,
          slack_webhook_url: nil,
          created_at: nil,
          updated_at: nil
        }, status: :ok
      end
    rescue => e
      Rails.logger.error "Error fetching settings: #{e.message}"
      render json: { error: 'Failed to fetch settings' }, status: :internal_server_error
    end

    # POST /api/settings
    # ユーザー設定を作成または更新
    def create
      settings = @repository.create_or_update(
        current_user_id,
        settings_params
      )

      render json: {
        user_id: settings['user_id'],
        meeting_title: settings['meeting_title'],
        auto_delete_days: settings['auto_delete_days'],
        slack_webhook_url: settings['slack_webhook_url'],
        created_at: settings['created_at'],
        updated_at: settings['updated_at']
      }, status: :ok
    rescue => e
      Rails.logger.error "Error creating/updating settings: #{e.message}"
      render json: { error: 'Failed to save settings' }, status: :internal_server_error
    end

    # POST /api/settings/slack/test
    # Slack Webhook のテスト送信
    def test_slack
      settings = @repository.find_by_user_id(current_user_id)

      if settings.nil? || settings['slack_webhook_url'].blank?
        render json: { error: 'Slack webhook URL is not configured' }, status: :unprocessable_entity
        return
      end

      webhook_url = settings['slack_webhook_url']

      begin
        response = HTTParty.post(
          webhook_url,
          body: {
            text: "🦆 QuackNote からのテスト通知です\n\nSlack 通知が正常に設定されています。",
            username: "QuackNote",
            icon_emoji: ":duck:"
          }.to_json,
          headers: {
            'Content-Type' => 'application/json'
          }
        )

        if response.success?
          render json: {
            message: 'Slack notification sent successfully',
            webhook_url: webhook_url
          }, status: :ok
        else
          Rails.logger.error "Slack notification failed: #{response.code} - #{response.body}"
          render json: {
            error: 'Failed to send Slack notification',
            details: response.body
          }, status: :bad_request
        end
      rescue => e
        Rails.logger.error "Error sending Slack notification: #{e.message}"
        render json: {
          error: 'Failed to send Slack notification',
          details: e.message
        }, status: :internal_server_error
      end
    end

    private

    def set_repository
      @repository = UserSettingsRepository.new
    end

    # Strong Parameters
    def settings_params
      params.require(:settings).permit(
        :meeting_title,
        :auto_delete_days,
        :slack_webhook_url
      )
    rescue ActionController::ParameterMissing
      # settings パラメータがない場合は空の Hash を返す
      {}
    end
  end
end
