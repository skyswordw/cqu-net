FROM alpine:latest

RUN apk add --no-cache curl iputils

COPY cqu_net.sh /app/cqu_net.sh
RUN chmod +x /app/cqu_net.sh

WORKDIR /app

CMD ["./cqu_net.sh"] 