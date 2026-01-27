# Use official image
FROM typesense/typesense:30.0

# Install curl
RUN apt-get update -qq && \
    apt-get install -qq -y --no-install-recommends curl && \
    rm -rf /var/lib/apt/lists/*

# Information
LABEL maintainer="Fedor Batonogov <f.batonogov@yandex.ru>"
LABEL description="Typesense search engine with healthcheck"

# Configure healthcheck
HEALTHCHECK --interval=30s \
    --timeout=10s \
    --start-period=30s \
    --retries=3 \
    CMD [ "curl", "--fail", "http://localhost:8108/health" ]
