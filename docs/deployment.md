# Backend Deployment Guide

Since this is a FastAPI application, deploying it is straightforward. For hackathons and rapid prototyping, we recommend using platform-as-a-service (PaaS) providers like **Render**, **Railway**, or **Heroku**.

Here is a step-by-step guide to deploying the NoorAI backend on **Render**.

## Prerequisites
- A GitHub repository with your `backend` code.
- A Render account (free tier works great).

## Option 1: Quick Deploy via Render

1. **Push your code to GitHub**: Make sure the `backend` folder contains `main.py` and `requirements.txt`.
2. **Create a new Web Service** on Render.
3. **Connect your GitHub repository**.
4. **Configure the Service**:
   - **Root Directory**: `backend` (if your code is in the backend folder).
   - **Environment**: Python
   - **Build Command**: `pip install -r requirements.txt`
   - **Start Command**: `uvicorn main:app --host 0.0.0.0 --port $PORT`
5. **Environment Variables**:
   Add any required variables in the Render dashboard:
   - `GEMINI_API_KEY`: Your Gemini API key.
6. **Deploy**: Click "Create Web Service". Render will automatically build and deploy your FastAPI backend.

## Option 2: Using Docker

If you prefer to containerize your application for a VPS (like DigitalOcean or AWS EC2), you can use this `Dockerfile`:

```dockerfile
# /backend/Dockerfile
FROM python:3.11-slim

WORKDIR /app

# Copy requirements
COPY requirements.txt .

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Expose port
EXPOSE 8000

# Start command
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```

**To run it:**
```bash
cd backend
docker build -t noorai-backend .
docker run -d -p 8000:8000 -e GEMINI_API_KEY="your_api_key_here" noorai-backend
```

## Post-Deployment
Once deployed, your backend will be accessible at the provided URL (e.g., `https://noorai-backend.onrender.com`).
Update your Flutter app's base API URL to point to this new URL instead of `http://localhost:8000`.
