# Install nginx
apt-get install -y nginx

# Create config
cat > /etc/nginx/conf.d/llm-proxy.conf << 'EOF'
server {
    listen 6007;

    # Embedding
    location /v1/embeddings {
        proxy_pass http://127.0.0.1:8080;
        proxy_read_timeout 300s;
        proxy_buffering off;
    }

    # Reranker
    location /v1/score {
        proxy_pass http://127.0.0.1:8081;
        proxy_read_timeout 300s;
        proxy_buffering off;
    }

    # Coder — all other /v1/ routes
    location / {
        proxy_pass http://127.0.0.1:6006;
        proxy_read_timeout 300s;
        proxy_buffering off;
    }
}
EOF

# Remove default
rm -f /etc/nginx/sites-enabled/default

# Test and start
nginx -t && nginx