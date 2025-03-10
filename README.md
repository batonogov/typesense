# Typesense with Healthcheck in Docker

This repository provides a Docker image based on Typesense with an integrated healthcheck.
The healthcheck uses the curl utility to verify the service's health by pinging its endpoint.

## Project Features

- **Official Typesense Image**: The image is built on top of the official typesense Docker image.
- **Healthcheck**: A built-in healthcheck performs a request to <http://localhost:8108/health> to ensure the service is running properly.
- **Ease of Use**: A ready-to-use Docker image suitable for development and production environments.

## License

This project is licensed under the **MIT License**. See the [LICENSE](LICENSE) file for more details.
