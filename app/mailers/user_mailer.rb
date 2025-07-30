class UserMailer < ApplicationMailer
  default from: ENV.fetch('SMTP_USERNAME', nil)

  def confirmation_email(user)
    @user = user
    @confirmation_url = "#{ENV.fetch('FRONTEND_URL', nil)}/confirm-email?token=#{@user.confirmation_token}"

    # Debug
    Rails.logger.info '------------------------------------------------------------------------------------'
    Rails.logger.info "Sending email to: #{@user.email}"
    Rails.logger.info "SMTP Username: #{ENV.fetch('SMTP_USERNAME', 'NOT SET')}"
    Rails.logger.info "Frontend URL: #{ENV.fetch('FRONTEND_URL', 'NOT SET')}"

    mail(to: @user.email, subject: 'Conferma la tua registrazione')
  end
end
