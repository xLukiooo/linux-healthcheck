FROM ubuntu:22.04

RUN apt-get update && apt-get install -y --no-install-recommends \
    iproute2 \
    procps \
    curl \
    netcat-openbsd \
    dnsutils \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY server-healthcheck.sh .
RUN chmod +x server-healthcheck.sh

CMD ["./server-healthcheck.sh"]
