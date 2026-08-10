# SPDX-FileCopyrightText: 2026 Marcin Kaim
# SPDX-License-Identifier: Apache-2.0

# Base OS: Debian 13 (Trixie) Minimal Variant
FROM debian:trixie-slim

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

# Install system dependencies, C-libraries for WeasyPrint, and system fonts
RUN sed -i 's/Components: main/Components: main contrib/g' /etc/apt/sources.list.d/debian.sources \
    && apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    python3-venv \
    fonts-ibm-plex \
    fontconfig \
    libpango-1.0-0 \
    libpangoft2-1.0-0 \
    libgdk-pixbuf-2.0-0 \
    libffi-dev \
    shared-mime-info \
    && fc-cache -fv \
    && rm -rf /var/lib/apt/lists/*

# Create virtual environment and install Python dependencies
RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

RUN pip install --no-cache-dir \
    markdown-it-py \
    beautifulsoup4 \
    jinja2 \
    weasyprint

# Set working directory for application binaries
WORKDIR /app

# Copy application source files and default stylesheet
COPY src/ /app/

# Copy legal notices and REUSE license directory into the container
COPY NOTICE /app/NOTICE
COPY LICENSES/ /app/LICENSES/

# Prepare asset mount directory with appropriate permissions
RUN mkdir -p /tmp/assets && chmod 777 /tmp/assets

# Set entrypoint to run the Python preprocessor
ENTRYPOINT ["python3", "/app/cv_make.py"]
