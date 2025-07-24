# frozen_string_literal: true

module Api
  class AiController < ApplicationController
    def chat
      response = ChatCompletionService.new(user: current_user).call

      if response.success?
        render json: JSON.parse(response.body), status: :ok
      else
        render json: { error: 'AI service error', details: response.body }, status: :bad_gateway
      end
    end
  end
end
