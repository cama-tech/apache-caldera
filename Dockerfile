FROM debian:bookworm-slim

ARG CALDERA_VERSION=5.3.0
ARG VARIANT=full
ARG TZ=UTC

ENV DEBIAN_FRONTEND=noninteractive
ENV PATH=$PATH:/usr/local/go/bin

WORKDIR /usr/src

RUN apt-get update && apt-get install -y --no-install-recommends \
    git ca-certificates curl unzip python3 python3-dev python3-pip \
    mingw-w64 zlib1g gcc nodejs npm \
    && rm -rf /var/lib/apt/lists/*

# Instalar Go 1.22 manualmente
RUN curl -OL https://go.dev/dl/go1.22.0.linux-amd64.tar.gz && \
    tar -C /usr/local -xzf go1.22.0.linux-amd64.tar.gz && \
    rm go1.22.0.linux-amd64.tar.gz

RUN git clone --recursive --branch ${CALDERA_VERSION} https://github.com/apache/caldera.git

WORKDIR /usr/src/caldera

RUN cd plugins/magma && npm install && npm run build

RUN pip3 install --break-system-packages --no-cache-dir -r requirements.txt

RUN if [ "$VARIANT" = "full" ]; then \
      git clone --depth 1 https://github.com/redcanaryco/atomic-red-team.git plugins/atomic/data/atomic-red-team || true; \
      git clone --depth 1 https://github.com/center-for-threat-informed-defense/adversary_emulation_library plugins/emu/data/adversary-emulation-plans || true; \
    fi

RUN cd plugins/sandcat/gocat && go mod tidy && go mod download

RUN cd plugins/sandcat && ./update-agents.sh

EXPOSE 8888 8443 7010 7012 8853 8022 2222
EXPOSE 7011/udp

ENTRYPOINT ["python3", "server.py"]