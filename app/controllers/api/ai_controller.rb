module Api
  class AiController < ApplicationController
    include ActionController::Live

    def chat
      response.headers['Content-Type'] = 'text/event-stream'
      ChatCompletionService.new(user: current_user).stream_to(response.stream)
    rescue StandardError => e
      logger.error "Errore nello stream AI: #{e.message}"
      response.stream.write "data: Errore interno\n\n"
    ensure
      response.stream.close
    end
  end
end
