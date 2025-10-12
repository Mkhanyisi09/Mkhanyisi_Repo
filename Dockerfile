# Dockerfile - Production-ready Python Flask app
FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Copy and install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY app.py .

# Copy bin scripts
COPY bin/ ./bin/

# Copy tests (optional)
COPY tests/ ./tests/

# Make scripts executable
RUN chmod +x bin/*.sh

# Expose Flask port
EXPOSE 5000

# Run Flask app with Gunicorn
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "app:app", "--workers", "3", "--threads", "2", "--timeout", "30"]
