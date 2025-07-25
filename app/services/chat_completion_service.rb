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
      L'utente possiede esclusivamente criptovalute, **valuta solo asset crypto**. Escludi azioni, ETF, immobili, ecc. Questo è il suo portafoglio:
      #{formatted.join("\n")}
      
      Valore totale stimato: #{total.round(2)} EUR.
      
      # Obiettivo
      
      Dai un punteggio **0-100** sul portafoglio crypto, considerando:
      
      1. Memecoin e low-cap: Un'alta percentuale di token speculativi e a bassa capitalizzazione abbassa il punteggio.
      2. Crypto ad alta capitalizzazione: Investire in asset consolidati come Bitcoin o Ethereum migliora il punteggio.
      3. Stablecoin affidabili: La presenza di stablecoin ben capitalizzate aumenta la resilienza del portafoglio.
      4. Diversificazione tra ecosistemi: Un portafoglio distribuito su più blockchain e settori riduce il rischio sistemico.
      5. Liquidità degli asset: Asset liquidi e facilmente scambiabili rendono il portafoglio più flessibile.

      Oltre al punteggio, dai anche un titolo simpatico per definire la tipologia di investitore sulla base del suo portafoglio.
      
      ## Esempio di risposta formattata
      
      **Valutazione:** 82/100  
      **Tipologia di investitore:** Il Custode del Ledger   
      
      ---
      
      ### Analisi del portafoglio  
      
      1. **Memecoin e low-cap**: Bassa esposizione.  
      2. **Crypto ad alta capitalizzazione**: BTC ed ETH presenti.  
      3. **Stablecoin affidabili**: USDC e DAI presenti.  
      4. **Diversificazione tra ecosistemi**: Molto buona.  
      5. **Liquidità degli asset**: Elevata.  
      
      ---
      
      ### Raccomandazioni
      
      - Mantenere la diversificazione.  
      - Monitorare l'esposizione a memecoin.
      
      ---
      
      # Ora genera la risposta per il portafoglio dell'utente, **seguendo esattamente lo stile dell'esempio markdown sopra.**
    TEXT
  end
end
