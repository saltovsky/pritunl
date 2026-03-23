# Stage 1: Build
FROM alpine:3.19.1 AS builder
LABEL maintainer="Daniel Saltovsky [daniel@saltovsky.ru](mailto:daniel@saltovsky.ru)"
ENV VERSION="1.34.4575.42"

# Install build dependencies
RUN apk --no-cache add --update \
    go git breezy wget py3-pip \
    gcc python3 python3-dev make musl-dev linux-headers \
    libffi-dev openssl-dev py3-dnspython py3-requests \
    py3-setuptools py3-six openssl procps ca-certificates

RUN rm -f /usr/lib/python*/EXTERNALLY-MANAGED
RUN python3 -m ensurepip && pip3 install --no-cache-dir --upgrade pip

# Install Go
COPY --from=golang:1.22-alpine /usr/local/go/ /usr/local/go/
ENV PATH="/usr/local/go/bin:${PATH}"

# Install Pritunl DNS/Web
RUN go install github.com/pritunl/pritunl-dns@latest && \
    go install github.com/pritunl/pritunl-web@latest && \
    cp $HOME/go/bin/* /usr/bin

# Build Pritunl
RUN wget https://github.com/pritunl/pritunl/archive/refs/tags/${VERSION}.tar.gz && \
    tar zxvf ${VERSION}.tar.gz && \
    cd pritunl-${VERSION} && \
    python3 setup.py build && \
    pip3 install -r requirements.txt && \
    python3 setup.py install && \
    cd .. && \
    rm -rf ${VERSION} ${VERSION}.tar.gz

# Stage 2: Runtime
FROM alpine:3.19.1
ENV VERSION="1.34.4575.42"

# Install runtime dependencies only
RUN apk --no-cache add --update \
    python3 py3-pip py3-dnspython py3-requests \
    openssl procps ca-certificates openvpn iptables ip6tables ipset \
    bash # нужен для init.sh

# Copy binaries from builder
COPY --from=builder /usr/bin/pritunl-dns /usr/bin/
COPY --from=builder /usr/bin/pritunl-web /usr/bin/
COPY --from=builder /usr/local/lib/python*/site-packages/ /usr/lib/python*/site-packages/
COPY --from=builder /usr/bin/pritunl /usr/bin/

# Config tweaks
RUN sed -i -e '/^attributes/a prompt\t\t\t= yes' /etc/ssl/openssl.cnf && \
    sed -i -e '/countryName_max/a countryName_value\t\t= US' /etc/ssl/openssl.cnf && \
    mkdir -p /var/lib/pritunl

ADD rootfs /
EXPOSE 80 443 1194/tcp 1194/udp 1195/udp

ENTRYPOINT ["/init"]