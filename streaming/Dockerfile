FROM tiangolo/nginx-rtmp:latest

RUN apt-get update && apt-get install -y \
    ffmpeg \
    && rm -rf /var/lib/apt/lists/*

COPY nginx.conf /etc/nginx/nginx.conf

RUN mkdir -p /tmp/hls/radio

EXPOSE 1935 8082

CMD ["nginx", "-g", "daemon off;"]