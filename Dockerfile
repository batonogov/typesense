# Use official image
FROM typesense/typesense:29.0.rc12

# Copy curl utility from another image
COPY --from=ghcr.io/tarampampam/curl:8.13.0 /bin/curl /bin/curl

# Configure healthcheck: checks the endpoint every 5 seconds
HEALTHCHECK --interval=5s --timeout=5s --start-period=3s --retries=3 \
    CMD [ "curl", "--fail", "http://localhost:8108/health" ]
