test:
	docker build -t typesense:latest .
	CONTAINER_ID=$$(docker run --rm -d typesense:latest --data-dir /tmp --api-key=API_KEY_TEST); \
	echo "Waiting for container to become healthy..."; \
	TIMEOUT=30; \
	COUNTER=0; \
	until [ "$$(docker inspect --format='{{.State.Health.Status}}' $$CONTAINER_ID)" = "healthy" ] || [ $$COUNTER -eq $$TIMEOUT ]; do \
	    sleep 1; \
	    COUNTER=$$((COUNTER+1)); \
	done; \
	if [ $$COUNTER -eq $$TIMEOUT ]; then \
	    echo "Container did not become healthy in $$TIMEOUT seconds"; \
	    docker stop $$CONTAINER_ID; \
	    exit 1; \
	fi; \
	echo "Container is healthy"; \
	docker stop $$CONTAINER_ID
