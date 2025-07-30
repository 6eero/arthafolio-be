# app/services/chat_completion_service.rb

require 'langchain'

# ChatCompletionService handles AI-powered cryptocurrency portfolio analysis using Claude Sonnet 4.
#
# This service streams real-time analysis of a user's crypto holdings, evaluating portfolios
# based on diversification, risk factors, and asset quality. It implements prompt caching
# to optimize API costs by reusing static analysis criteria across requests.
#
# Features:
# - Real-time streaming responses for better UX
# - Prompt caching for cost optimization (90% savings on cached content)
# - Structured portfolio evaluation with scoring and recommendations
# - Error handling with user-friendly messages
# - Support for multiple asset categories and pricing data
#
# Usage:
#   service = ChatCompletionService.new(user: current_user)
#   service.stream_to(response.stream)
#
# API Costs (estimated):
# - ~$0.008-0.009 per analysis with prompt caching
# - Input: ~300-400 tokens, Output: ~400-600 tokens
# - Cached prompt reduces costs by 80% after first request
#
# Requirements:
# - User must have associated holdings with pricing data
# - ANTHROPIC_API_KEY environment variable
# - langchain gem for Claude API integration
#
# TODO: Implement rate limiting per user to control API costs
class ChatCompletionService
  MODEL_NAME = 'claude-sonnet-4-20250514'.freeze
  MAX_TOKENS = 1024

  def initialize(user:)
    @user = user
    @full_text = ''
  end

  def stream_to(stream)
    llm = Langchain::LLM::Anthropic.new(
      api_key: ENV.fetch('ANTHROPIC_API_KEY'),
      llm_options: {
        model: MODEL_NAME,
        max_tokens: MAX_TOKENS,
        temperature: 0.7
      }
    )

    system_prompt = static_prompt_header
    user_prompt = [
      {
        type: 'text',
        text: static_prompt_question,
        cache_control: { type: 'ephemeral' }
      },
      {
        type: 'text',
        text: portfolio_summary_for_prompt
      }
    ]

    llm.chat(
      system: system_prompt,
      messages: [
        {
          role: 'user',
          content: user_prompt
        }
      ],
      stream: proc { |chunk| handle_stream(chunk, stream) }
    )
  rescue StandardError => e
    Rails.logger.error "[ChatCompletionService] #{e.class} - #{e.message}\n#{e.backtrace.join("\n")}"
    stream.write("data: #{{
      type: 'ERROR',
      message: 'Errore interno: il team è stato avvisato.'
    }.to_json}\n\n")
  ensure
    stream.close
    Rails.logger.info '[ChatCompletionService] Streaming terminato.'
  end

  private

  def handle_stream(chunk, stream)
    text = chunk.dig('delta', 'text') || chunk['completion']
    return if text.blank?

    @full_text << text

    stream.write("data: #{{
      type: 'TEXT',
      message: text
    }.to_json}\n\n")
  end

  def static_prompt_header
    <<~PROMPT
      You are a crypto portfolio analyst.
      Your job is to evaluate users' cryptocurrency portfolios using expert-level reasoning.
    PROMPT
  end

  def static_prompt_question
    <<~PROMPT
      You are evaluating a cryptocurrency portfolio. Use these criteria:

      1. **Memecoins and low-caps**: High percentage reduces score
      2. **High-cap cryptocurrencies**: BTC/ETH increase score
      3. **Reliable stablecoins**: Improve portfolio resilience
      4. **Diversification**: Multiple chains/sectors reduce risk
      5. **Asset liquidity**: Tradeable assets add flexibility

      Provide a structured analysis with:
      - Overall score (1-10)
      - Key strengths
      - Main risks
      - Brief recommendations

      Here is the portfolio data:
    PROMPT
  end

  def portfolio_summary_for_prompt
    holdings = @user.holdings.includes(:user)
    prices_by_label = Price.where(label: holdings.map(&:label)).index_by(&:label)

    formatted = holdings.map do |h|
      price = prices_by_label[h.label]&.price || 0
      value = h.quantity.to_f * price.to_f
      "#{h.label} (#{h.category}): #{h.quantity} × #{price} = #{value.round(2)} EUR"
    end

    total = formatted.sum { |line| line[/= ([\d\.]+)/, 1].to_f }

    <<~TEXT
      Portfolio:
      #{formatted.join("\n")}

      Estimated total value: #{total.round(2)} EUR.
    TEXT
  end
end
