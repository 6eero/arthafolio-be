class ChatCompletionService
  require 'net/http'
  require 'json'
  require 'uri'

  def initialize(user:)
    @user = user
  end

  def stream_to(stream)
    prompt = format_holdings_for_prompt
    uri = URI('https://openrouter.ai/api/v1/chat/completions')

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

    Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
      http.request(request) do |response|
        response.read_body do |chunk|
          chunk.lines.each do |line|
            next unless line.start_with?('data: ')

            content = line.delete_prefix('data: ').strip
            next if content == '[DONE]'

            stream.write("data: #{content}\n\n")
          end
        end
      end
    end
  rescue StandardError => e
    stream.write("data: Errore: #{e.message}\n\n")
  ensure
    stream.close
  end

  def format_holdings_for_prompt
    holdings = @user.holdings.includes(:user)
    prices_by_label = Price.where(label: holdings.map(&:label)).index_by(&:label)

    formatted = holdings.map do |h|
      price = prices_by_label[h.label]&.price || 0
      value = h.quantity.to_f * price.to_f
      "#{h.label} (#{h.category}): #{h.quantity} x #{price} = #{value.round(2)} EUR"
    end

    total = formatted.sum { |line| line[/= ([\d\.]+)/, 1].to_f }

    <<~TEXT
      L'utente possiede esclusivamente criptovalute:
      #{formatted.join("\n")}

      Valore totale stimato: #{total.round(2)} EUR.

      **Valuta solo asset crypto.** Escludi azioni, ETF, immobili, ecc.

      ### Obiettivo:

      Dai un punteggio **0-100** su **diversificazione e bilanciamento** del portafoglio crypto, considerando:

      1. **Distribuzione**: meglio ≥3 asset ben bilanciati; peggio se 1-2 asset dominano (>60%).
      2. **Tipologia**: + punti per BTC, ETH, infrastrutturali; – punti per memecoin/speculativi.
      3. **Categorie**: premia varietà (layer-1, staking, utility); nessuna penalità per stablecoin o DeFi assenti.
      4. **Rischio BTC**: BTC è riferimento, ma >75% è eccessiva concentrazione.

      ### Risposta:

      * **Valutazione** (es: **72/100**)
      * **Breve spiegazione** (max 3-4 frasi)
      * Formatta in **markdown**, chiaro e leggibile.
    TEXT
  end
end
