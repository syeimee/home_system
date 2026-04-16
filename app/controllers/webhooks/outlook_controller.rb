module Webhooks
  class OutlookController < ApplicationController
    skip_forgery_protection

    def create
      if params[:validationToken].present?
        render plain: params[:validationToken], status: :ok
        return
      end

      unless valid_client_state?
        head :unauthorized
        return
      end

      OutlookSyncJob.perform_later
      head :ok
    end

    private

    def valid_client_state?
      value = params[:value]
      return false unless value.is_a?(Array)

      value.all? { |v| v[:clientState] == ENV.fetch('MS_WEBHOOK_SECRET') }
    end
  end
end
