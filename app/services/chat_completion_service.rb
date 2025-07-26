# rubocop:disable Layout/TrailingWhitespace

class ChatCompletionService
  require 'net/http'
  require 'json'
  require 'uri'

  def initialize(user:)
    @user = user
    @accumulated_reasoning = ''
    @accumulated_text = ''
    Rails.logger.info "[ChatCompletionService] Inizializzato per user_id=#{@user.id}"
  end

  def stream_to(stream)
    prompt = format_holdings_for_prompt
    Rails.logger.info '------------------------------------------------------------------------------------------------'
    Rails.logger.info "[ChatCompletionService] Prompt generato:\n#{prompt}"
    Rails.logger.info '------------------------------------------------------------------------------------------------'

    uri = URI('https://openrouter.ai/api/v1/chat/completions')
    Rails.logger.info "[ChatCompletionService] Richiesta a #{uri}"

    request = Net::HTTP::Post.new(uri)
    request['Content-Type'] = 'application/json'
    request['Authorization'] = "Bearer #{ENV.fetch('OPENROUTER_API_KEY')}"

    request.body = {
      model: 'deepseek/deepseek-r1-0528-qwen3-8b:free',
      temperature: 0.7,
      stream: true,
      messages: [
        { role: 'user', content: prompt }
      ]
    }.to_json

    Rails.logger.info '[ChatCompletionService] Inizio richiesta HTTP...'

    Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
      http.request(request) do |response|
        Rails.logger.info '[ChatCompletionService] Ricevuta risposta. Streaming in corso...'
        response.read_body do |chunk|
          chunk.lines.each do |line|
            next unless line.start_with?('data: ')

            content = line.delete_prefix('data: ').strip
            next if content == '[DONE]'

            # content is in this form:
            # {
            #   "id": "gen-1753457518-ubGb4VPl31sENbJAdZMx",
            #   "provider": "Chutes",
            #   "model": "deepseek/deepseek-r1-0528-qwen3-8b:free",
            #   "object": "chat.completion.chunk",
            #   "created": 1753457518,
            #   "choices": [
            #     {
            #       "index": 0,
            #       "delta": {
            #         "role": "assistant",
            #         "content": "",
            #         "reasoning": " la",
            #         "reasoning_details": []
            #       },
            #       "finish_reason": null,
            #       "native_finish_reason": null,
            #       "logprobs": null
            #     }
            #   ]
            # }

            parsed = JSON.parse(content)

            reasoning = parsed.dig('choices', 0, 'delta', 'reasoning')
            text = parsed.dig('choices', 0, 'delta', 'content')

            if reasoning.present?
              @accumulated_reasoning << reasoning
              Rails.logger.info "🔵 REASONING PARZIALE: #{@accumulated_reasoning}"
              stream.write("data: #{{ type: 'REASONING', message: reasoning }.to_json}\n\n")
            end

            next if text.blank?

            @accumulated_text << text
            Rails.logger.info "🟣 TEXT PARZIALE: #{@accumulated_text}"
            stream.write("data: #{{ type: 'TEXT', message: text }.to_json}\n\n")
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
      \#{formatted.join("\n")}
      
      Estimated total value: #{total.round(2)} EUR.
      
      # Objective
      
      Give a **0-100 score** to the crypto portfolio, considering the following criteria:
      
      1. **Memecoins and low-caps**: A high percentage of speculative or low-cap tokens lowers the score.
      2. **High-cap cryptocurrencies**: Investing in established assets like Bitcoin or Ethereum increases the score.
      3. **Reliable stablecoins**: The presence of well-capitalized stablecoins improves portfolio resilience.
      4. **Diversification across ecosystems**: A portfolio spread across multiple blockchains and sectors reduces systemic risk.
      5. **Asset liquidity**: Liquid and easily tradable assets make the portfolio more flexible.
      
      In addition to the score, provide a fun title to define the investor type based on their portfolio.
      
      ## Example formatted response
      
      **Rating:** 82/100  
      **Investor type:** The Ledger Guardian  
      
      ---
      
      ### Portfolio Analysis  
      
      1. **Memecoins and low-caps**: Low exposure.  
      2. **High-cap cryptocurrencies**: BTC and ETH present.  
      3. **Reliable stablecoins**: USDC and DAI included.  
      4. **Diversification across ecosystems**: Very good.  
      5. **Asset liquidity**: High.  
      
      ---
      
      ### Recommendations  
      
      * Maintain diversification.  
      * Monitor memecoin exposure.  
      
      ---
      
      # Now generate the response for the user's portfolio, **strictly following the markdown style of the example above.**
      
    TEXT
  end
end
