FROM python:3.10-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    ffmpeg \
    && rm -rf /var/lib/apt/lists/*

# Copy project files
COPY . .

# Install Python dependencies
RUN pip install --no-cache-dir -e .

# Create model cache directory
RUN mkdir -p /root/.cache/huggingface

# Pre-download models during build (using ARG for token)
ARG HF_TOKEN
ENV HUGGINGFACE_HUB_TOKEN=$HF_TOKEN
ENV HF_ENDPOINT=https://hf-mirror.com

# Pre-download pyannote models with error handling
RUN python -c "\
import os; \
print('Starting model download...'); \
print(f'HF_TOKEN available: {\"yes\" if os.getenv(\"HUGGINGFACE_HUB_TOKEN\") else \"no\"}'); \
from pyannote.audio import Pipeline; \
print('Downloading pyannote speaker diarization model...'); \
try: \
    pipeline = Pipeline.from_pretrained('pyannote/speaker-diarization-3.1'); \
    print('Model downloaded successfully'); \
except Exception as e: \
    print(f'Error downloading model: {e}'); \
    print('Trying alternative model...'); \
    try: \
        pipeline = Pipeline.from_pretrained('pyannote/speaker-diarization'); \
        print('Alternative model downloaded successfully'); \
    except Exception as e2: \
        print(f'Error downloading alternative model: {e2}'); \
        print('Continuing without model pre-download'); \
"

# Expose Gradio port
EXPOSE 7860

# Set the command to run the demo with share=True
CMD ["python", "demo/app.py", "--share"]