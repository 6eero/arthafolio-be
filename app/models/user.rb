# frozen_string_literal: true

class User < ApplicationRecord
  # Aggiunge metodi per impostare e autenticare tramite password sicura.
  # Richiede una colonna `password_digest` nel database.
  has_secure_password

  # Validazioni
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 6 }, if: -> { new_record? || !password.nil? }
  validates :username, presence: true, uniqueness: { case_sensitive: false }

  has_many :holdings, dependent: :destroy
  has_many :portfolio_snapshots, dependent: :destroy
end
