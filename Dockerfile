# Use official image
FROM typesense/typesense:29.0.rc4

# Copy curl utility from another image
COPY --from=ghcr.io/tarampampam/curl:8.13.0 /bin/curl /bin/curl

# Information
LABEL maintainer="Fedor Batonogov <f.batonogov@yandex.ru>"
LABEL description="Typesense search engine with healthcheck"

# Configure healthcheck
HEALTHCHECK --interval=30s \
    --timeout=10s \
    --start-period=30s \
    --retries=3 \
    CMD [ "curl", "--fail", "http://localhost:8108/health" ]
