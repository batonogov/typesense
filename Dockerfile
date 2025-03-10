FROM typesense/typesense:28.0

# RUN apt update \
#     && apt install -y -qq --no-install-recommends \
#     curl \
#     && apt clean \
#     && rm -rf /var/lib/apt/lists/*

# Копируем curl для работы HEALTHCHECK
COPY --from=ghcr.io/tarampampam/curl:8.10.1 /bin/curl /bin/curl
# Запускаем healthcheck, проверяющий доступность веб-сервера на порту 8080
HEALTHCHECK --interval=5s --timeout=5s --start-period=3s --retries=3 \
    CMD [ "curl", "--fail", "http://localhost:8108/health" ]
