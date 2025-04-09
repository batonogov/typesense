# Конфигурация тестов
TEST_API_KEY ?= API_KEY_TEST
TEST_TIMEOUT ?= 30
TEST_CONTAINER_NAME ?= typesense-test-$(shell date +%s)

.PHONY: test test-api test-performance clean

test: test-api test-performance

test-api:
	@echo "Building test container..."
	docker build -t typesense:test .

	@echo "Starting test container..."
	$(eval CONTAINER_ID := $(shell docker run --rm -d \
		--name $(TEST_CONTAINER_NAME) \
		-p 8108:8108 \
		--health-cmd="curl -f http://localhost:8108/health || exit 1" \
		--health-interval=1s \
		--health-timeout=1s \
		--health-retries=3 \
		-e TYPESENSE_API_KEY=$(TEST_API_KEY) \
		typesense:test \
		--data-dir /tmp \
		--api-key=$(TEST_API_KEY) \
		2>&1 || echo "FAILED"))

	@if [ "$(CONTAINER_ID)" = "FAILED" ]; then \
		echo "Failed to start container"; \
		exit 1; \
	fi

	@echo "Container ID: $(CONTAINER_ID)"
	@echo "Waiting for container to become healthy..."
	@TIMEOUT=$(TEST_TIMEOUT); \
	COUNTER=0; \
	while [ $$COUNTER -lt $$TIMEOUT ]; do \
		HEALTH_STATUS=$$(docker inspect --format='{{.State.Health.Status}}' $(CONTAINER_ID) 2>/dev/null || echo "unknown"); \
		echo "Health status: $$HEALTH_STATUS ($$COUNTER/$$TIMEOUT)"; \
		if [ "$$HEALTH_STATUS" = "healthy" ]; then \
			break; \
		fi; \
		sleep 1; \
		COUNTER=$$((COUNTER+1)); \
	done; \
	if [ $$COUNTER -eq $$TIMEOUT ]; then \
		echo "Container did not become healthy in $$TIMEOUT seconds"; \
		echo "Container logs:"; \
		docker logs $(CONTAINER_ID) 2>/dev/null || echo "Could not get container logs"; \
		docker stop $(CONTAINER_ID) 2>/dev/null || true; \
		exit 1; \
	fi

	@echo "Running API tests..."
	./test_api.sh $(TEST_API_KEY)

	@echo "Running performance tests..."
	chmod +x ./test_performance.sh
	./test_performance.sh $(TEST_API_KEY)

	@echo "Stopping test container..."
	docker stop $(CONTAINER_ID)

test-performance: test-api
	@echo "Performance tests already run as part of test-api target"

clean:
	@echo "Cleaning up test containers..."
	docker ps -a --filter "name=typesense-test" --format "{{.ID}}" | xargs -r docker rm -f
