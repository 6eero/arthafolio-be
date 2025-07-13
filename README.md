# 🧠 Arthafolio Backend

This is the backend codebase for **Arthafolio**, a cryptocurrency portfolio tracker built with Rails and PostgreSQL. It integrates with the CoinMarketCap API to fetch real-time crypto data and provides endpoints to support a frontend client. The backend is containerized using Docker for easier local development and production deployment.

---

## 🚀 How to Deploy

Follow these steps to set up and run the backend locally or in production.

### 1. Clone the Repository

```bash
git clone https://github.com/6eero/arthafolio-be.git
cd arthafolio-be
```

### 2. Set Up Environment Variables

Edit the `.env.example` file and fill in the required values:

```env
RAILS_ENV=            # "development" or "production"
CMC_API_KEY=          # Your CoinMarketCap API key
DATABASE_URL=         # e.g., postgres://user:password@host:port/dbname
```

Then copy the example file to the correct environment file:

```bash
cp .env.example .env.development   # For development
cp .env.example .env.production    # For production
```

### 3. Run the Application

Use Docker Compose to build and run the containers:

```bash
ENV_FILE=.env.<environment> docker-compose up --build
```

Replace `<environment>` with either `development` or `production` depending on your setup.