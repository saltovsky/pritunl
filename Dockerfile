FROM alpine:3.19.1
LABEL maintainer="Daniel Saltovsky [daniel@saltovsky.ru](mailto:daniel@saltovsky.ru)"
ENV VERSION="1.34.4575.42"

# Install build + runtime deps in one layer
RUN apk --no-cache add --update \
    go git breezy wget \
    python3 py3-pip py3-setuptools py3-wheel py3-six py3-dnspython py3-requests \
    gcc python3-dev make musl-dev linux-headers \
    libffi-dev openssl-dev openssl procps ca-certificates \
    openvpn iptables ip6tables ipset bash

# Bypass PEP 668 externally-managed-environment protection
ENV PIP_BREAK_SYSTEM_PACKAGES=1

# Install Go
COPY --from=golang:1.22-alpine /usr/local/go/ /usr/local/go/
ENV PATH="/usr/local/go/bin:${PATH}"

# Install Pritunl helper tools
RUN go install github.com/pritunl/pritunl-dns@latest && \
    go install github.com/pritunl/pritunl-web@latest && \
    cp $HOME/go/bin/* /usr/bin/

# Install Pritunl with proper metadata (pip install вместо setup.py install)
RUN wget -q https://github.com/pritunl/pritunl/archive/refs/tags/${VERSION}.tar.gz && \
    tar xf ${VERSION}.tar.gz && \
    cd pritunl-${VERSION} && \
    pip install --no-cache-dir . && \
    cd .. && \
    rm -rf ${VERSION} ${VERSION}.tar.gz

# OpenSSL config for certificate generation
RUN sed -i -e '/^attributes/a prompt\t\t\t= yes' /etc/ssl/openssl.cnf && \
    sed -i -e '/countryName_max/a countryName_value\t\t= US' /etc/ssl/openssl.cnf && \
    mkdir -p /var/lib/pritunl

# Copy init script directly
COPY init.sh /init
RUN chmod +x /init

EXPOSE 80 443 1194/tcp 1194/udp 1195/udp

ENTRYPOINT ["/init"]