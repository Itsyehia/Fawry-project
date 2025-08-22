FROM python:3.9-slim
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    default-libmysqlclient-dev \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt /app/
RUN pip install --no-cache-dir -r requirements.txt

COPY . /app

# Set Flask environment variables
ENV FLASK_APP=app.py
ENV FLASK_ENV=production

EXPOSE 5002
CMD ["python", "-m", "flask", "run", "--host=0.0.0.0", "--port=5002"]