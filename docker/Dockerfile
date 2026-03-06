# Dify All-in-One: API + Worker + Web + Plugin Daemon in a single container
# Stateless — DB, Redis, S3 are external managed services

FROM langgenius/dify-api:latest AS api
FROM langgenius/dify-web:latest AS web
FROM langgenius/dify-plugin-daemon:0.5.3-local AS plugin-daemon

# Final image based on API
FROM langgenius/dify-api:latest

USER root

# Install nginx, supervisord, and postgresql-client (for init-db)
RUN apt-get update && \
    apt-get install -y --no-install-recommends nginx supervisor postgresql-client && \
    rm -rf /var/lib/apt/lists/*

# Copy web frontend from web image
COPY --from=web /app /app-web

# Copy plugin daemon binary
COPY --from=plugin-daemon /app/main /app/plugin-daemon/main
COPY --from=plugin-daemon /app/.tiktoken /app/plugin-daemon/.tiktoken
RUN chmod +x /app/plugin-daemon/main && \
    mkdir -p /app/plugin-daemon/storage/cwd

# Config files
COPY nginx.conf /etc/nginx/sites-available/default
COPY supervisord.conf /etc/supervisor/conf.d/dify.conf

# Scripts
COPY init-db.sh /usr/local/bin/init-db.sh
COPY start.sh /usr/local/bin/start.sh
COPY run-plugin-daemon.sh /usr/local/bin/run-plugin-daemon.sh
RUN chmod +x /usr/local/bin/init-db.sh /usr/local/bin/start.sh /usr/local/bin/run-plugin-daemon.sh

# Override entrypoint
ENTRYPOINT []

ENV DIFY_PORT=5100
ENV MIGRATION_ENABLED=true

EXPOSE 5001

CMD ["/usr/local/bin/start.sh"]
