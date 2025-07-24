FROM python:3.9-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    g++ \
    make \
    && rm -rf /var/lib/apt/lists/*

# Install Rasa
RUN pip install rasa==3.6.4

# Copy Rasa files
COPY . .

# Expose port
EXPOSE 5005

# Train model on startup if no model exists
CMD ["bash", "-c", "if [ ! -d 'models' ] || [ -z \"$(ls -A models)\" ]; then rasa train; fi && rasa run --enable-api --cors '*' --debug"]