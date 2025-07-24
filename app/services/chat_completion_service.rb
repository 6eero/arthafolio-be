class ChatCompletionService
  include HTTParty
  base_uri 'https://openrouter.ai/api/v1'

  def initialize(user:)
    @user = user
  end

  def call
    prompt = format_holdings_for_prompt

    Rails.logger.info "[Prompt to AI]:\n#{prompt}"

    self.class.post('/chat/completions',
                    headers: {
                      'Content-Type' => 'application/json',
                      'Authorization' => "Bearer #{ENV.fetch('OPENROUTER_API_KEY', nil)}"
                    },
                    body: {
                      model: 'deepseek/deepseek-r1-0528-qwen3-8b:free',
                      temperature: 0.7,
                      messages: [
                        {
                          role: 'user',
                          content: prompt
                        }
                      ]
                    }.to_json)
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
