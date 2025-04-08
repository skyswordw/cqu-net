FROM alpine:latest

# Install necessary tools: curl for HTTP requests, iputils for ping, 
# musl-utils for iconv (character encoding conversion)
RUN apk add --no-cache curl iputils musl-utils

COPY cqu_net.sh /app/cqu_net.sh
RUN chmod +x /app/cqu_net.sh

WORKDIR /app

CMD ["./cqu_net.sh"]