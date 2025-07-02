#!/bin/bash
set -e

# (Opzionale) Attendi qualche secondo
sleep 5

# Setup database:
# Combina:
#   - db:create: crea il database se non esiste.
#   - db:schema:load o db:migrate: crea o aggiorna lo schema.
#   - db:seed: inserisce dati di esempio, se presenti.
bundle exec rake db:prepare

# Run Rails server
exec bundle exec rails server -b 0.0.0.0
