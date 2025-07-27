# rubocop:disable Layout/TrailingWhitespace
require 'net/http'
require 'json'
require 'uri'

class ChatCompletionService
  API_URL = 'https://openrouter.ai/api/v1/chat/completions'.freeze
  MODEL_NAME = 'qwen/qwen3-coder:free'.freeze

  def initialize(user:)
    @user = user
    @full_text = ''
  end

  def stream_to(stream)
    prompt = format_holdings_for_prompt
    uri = URI(API_URL)
    
    request = Net::HTTP::Post.new(uri)
    request['Content-Type'] = 'application/json'
    request['Authorization'] = "Bearer #{ENV.fetch('OPENROUTER_API_KEY')}"

    request.body = {
      model: MODEL_NAME,
      temperature: 0.7,
      stream: true,
      messages: [
        { role: 'user', content: prompt }
      ]
    }.to_json

    Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
      http.request(request) do |response|
        # --- ERROR FROM OPENROUTER ---
        unless response.is_a?(Net::HTTPOK)
          error_body = response.body 
          Rails.logger.error "[ChatCompletionService] ERRORE DALL'API: #{response.code} #{response.message} #{error_body}"
          stream.write("data: #{{ type: 'ERROR', 
                                  message: "API Error: #{response.code} - Controlla i log del server." }.to_json}\n\n")
          return 
        end

        Rails.logger.info '------------------------------------------------------------------------------------------------'
        Rails.logger.info "[ChatCompletionService] Prompt generato:\n#{prompt}"
        Rails.logger.info "[ChatCompletionService] Inizio tichiesta HTTP a #{uri}"
        Rails.logger.info '[ChatCompletionService] Ricevuta risposta. Streaming in corso...'
        Rails.logger.info '------------------------------------------------------------------------------------------------'
        
        response.read_body do |chunk|
          chunk.lines.each do |line|
            next unless line.start_with?('data: ')

            content = line.delete_prefix('data: ').strip

            if content == '[DONE]'
              Rails.logger.info '[ChatCompletionService] Streaming completato. Invio del messaggio finale con testo completo.'
              stream.write("data: #{{ type: 'COMPLETE', message: 'testo temporaneo a scopo di debug' }.to_json}\n\n")
              break 
            end

            begin
              parsed = JSON.parse(content)
              text = parsed.dig('choices', 0, 'delta', 'content')
              next if text.blank?

              @full_text << text
              stream.write("data: #{{ type: 'TEXT', message: text }.to_json}\n\n")
            rescue JSON::ParserError => e
              Rails.logger.warn "[ChatCompletionService] JSON non valido: #{e.message} - content: '#{content}'"
              next
            end
          end
        end
      end
    end
  rescue StandardError => e
    Rails.logger.error "[ChatCompletionService] Errore durante la richiesta: #{e.message}"
    stream.write("data: Errore: #{e.message}\n\n")
  ensure
    Rails.logger.info '[ChatCompletionService] Streaming completato. Chiusura stream.'
    stream.close
  end

  def format_holdings_for_prompt
    holdings = @user.holdings.includes(:user)
    Rails.logger.info "[ChatCompletionService] Holdings trovati: #{holdings.count}"

    prices_by_label = Price.where(label: holdings.map(&:label)).index_by(&:label)
    Rails.logger.info "[ChatCompletionService] Prezzi trovati: #{prices_by_label.keys.join(', ')}"

    formatted = holdings.map do |h|
      price = prices_by_label[h.label]&.price || 0
      value = h.quantity.to_f * price.to_f
      "#{h.label} (#{h.category}): #{h.quantity} x #{price} = #{value.round(2)} EUR"
    end

    total = formatted.sum { |line| line[/= ([\d\.]+)/, 1].to_f }
    Rails.logger.info "[ChatCompletionService] Valore totale stimato: #{total.round(2)} EUR"

    <<~TEXT
      The user exclusively holds cryptocurrencies, **only crypto assets are considered**. Exclude stocks, ETFs, real estate, etc. This is their portfolio:
      #{formatted.join("\n")}
      
      Estimated total value: #{total.round(2)} EUR.
      
      # Objective
      
      Give an opinion to the crypto portfolio, considering the following criteria:
      
      1. **Memecoins and low-caps**: A high percentage of speculative or low-cap tokens lowers the score.
      2. **High-cap cryptocurrencies**: Investing in established assets like Bitcoin or Ethereum increases the score.
      3. **Reliable stablecoins**: The presence of well-capitalized stablecoins improves portfolio resilience.
      4. **Diversification across ecosystems**: A portfolio spread across multiple blockchains and sectors reduces systemic risk.
      5. **Asset liquidity**: Liquid and easily tradable assets make the portfolio more flexible.
    TEXT
  end
end
