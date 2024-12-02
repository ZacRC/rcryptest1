# Use the official Python image from the Docker Hub
FROM python:3.10-slim

# Prevents Python from writing pyc files to disk
ENV PYTHONDONTWRITEBYTECODE 1

# Ensures that Python output is sent straight to the terminal without buffering
ENV PYTHONUNBUFFERED 1

# Set the working directory in the container
WORKDIR /code

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    libpq-dev \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Upgrade pip
RUN pip install --upgrade pip

# Copy the requirements file into the container
COPY requirements.txt /code/

# Install Python dependencies
RUN pip install -r requirements.txt

# Copy the entire project into the container
COPY . /code/

# Create directory for static files
RUN mkdir -p /code/staticfiles && \
    chmod -R 755 /code/staticfiles

# Expose port 8000 to the host
EXPOSE 8000

# Define the default command to run the Django application using Gunicorn
CMD ["gunicorn", "myproject.wsgi:application", "--bind", "0.0.0.0:8000"]

# Add to your Dockerfile before the CMD line
RUN python manage.py collectstatic --noinput
