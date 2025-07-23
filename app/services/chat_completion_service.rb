class ChatCompletionService
  include HTTParty
  base_uri 'https://openrouter.ai/api/v1'

  def initialize(user:, user_message:)
    @user = user
    @user_message = user_message
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
                      model: 'deepseek/deepseek-r1-0528:free',
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
      L'utente possiede i seguenti asset:
      #{formatted.join("\n")}

      Valore totale stimato: #{total.round(2)} EUR.

      Fornisci una valutazione da 0 a 100 su quanto è ben bilanciata e diversificata questa asset allocation. Spiega brevemente il perché. Formatta tutta la risposta in markdown.
    TEXT
  end
end
