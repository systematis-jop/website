# Use an Nginx base image
FROM nginx:latest

# Copy the static files from Hugo’s public directory to the Nginx web root
COPY public /usr/share/nginx/html

# Expose port 80 for web traffic
EXPOSE 80
