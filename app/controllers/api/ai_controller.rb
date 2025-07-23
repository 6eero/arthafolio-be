# frozen_string_literal: true

module Api
  class AiController < ApplicationController
    def chat
      user_message = params[:message]

      if user_message.blank?
        render json: { error: 'Message is required' }, status: :bad_request
        return
      end

      Rails.logger.info "[OpenRouter] current_user: #{current_user}"

      response = ChatCompletionService.new(user: current_user, user_message: params[:message]).call

      Rails.logger.info "[OpenRouter] Response status: #{response.code}"
      Rails.logger.info "[OpenRouter] Response body: #{response.body}"

      if response.success?
        render json: JSON.parse(response.body), status: :ok
      else
        render json: { error: 'AI service error', details: response.body }, status: :bad_gateway
      end
    end
  end
end
