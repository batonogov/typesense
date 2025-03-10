test:
	docker build -t typesense:latest .
	docker images
	docker run -rm typesense:latest --data-dir /tmp --api-key=API_KEY_TEST
