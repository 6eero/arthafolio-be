FROM ruby:3.2

# Installa dipendenze di sistema, incluso il client PostgreSQL
RUN apt-get update -qq && apt-get install -y \
    build-essential \
    libpq-dev \
    postgresql-client \
    nodejs \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY Gemfile* ./
RUN gem install bundler && bundle install

COPY . .

COPY entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh

EXPOSE 3000

CMD ["bash", "/usr/bin/entrypoint.sh"]
