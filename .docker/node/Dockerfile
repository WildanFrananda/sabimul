FROM node:20-alpine

# Set working directory
WORKDIR /var/www/html

# Install dependencies
RUN apk add --no-cache bash

# Copy entry point script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Expose port 5173 for Vite
EXPOSE 5173

# Start Vite server
ENTRYPOINT ["/entrypoint.sh"]