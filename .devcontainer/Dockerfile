FROM mcr.microsoft.com/devcontainers/python:3.11-bookworm

RUN apt-get update && apt-get install -y \
    gdal-bin \
    libgdal-dev \
    libgeos-dev \
    libproj-dev \
    postgresql-client \
    postgis \
    && rm -rf /var/lib/apt/lists/*
