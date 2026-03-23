FROM alpine:3.19.1
LABEL maintainer="Daniel Saltovsky [daniel@saltovsky.ru](mailto:daniel@saltovsky.ru)"
ENV VERSION="1.34.4575.42"

# Build deps
RUN apk --no-cache add --update \
    go git breezy wget py3-pip \
    gcc python3 python3-dev make musl-dev linux-headers \
    libffi-dev openssl-dev py3-dnspython py3-requests \
    py3-setuptools py3-six openssl procps ca-certificates openvpn \
    iptables ip6tables ipset bash

# Fix Python EXTERNALLY-MANAGED
RUN rm -f /usr/lib/python*/EXTERNALLY-MAGED && \
    python3 -m ensurepip && \
    pip3 install --no-cache-dir --upgrade pip setuptools wheel

# Install Go
COPY --from=golang:1.22-alpine /usr/local/go/ /usr/local/go/
ENV PATH="/usr/local/go/bin:${PATH}"

# Install Pritunl helpers
RUN go install github.com/pritunl/pritunl-dns@latest && \
    go install github.com/pritunl/pritunl-web@latest && \
    cp $HOME/go/bin/* /usr/bin/

# Install Pritunl (ИСПРАВЛЕНО: pip install вместо setup.py install)
RUN wget https://github.com/pritunl/pritunl/archive/refs/tags/${VERSION}.tar.gz && \
    tar zxvf ${VERSION}.tar.gz && \
    cd pritunl-${VERSION} && \
    pip3 install --no-cache-dir . && \
    cd .. && \
    rm -rf ${VERSION} ${VERSION}.tar.gz

# OpenSSL config tweaks
RUN sed -i -e '/^attributes/a prompt\t\t\t= yes' /etc/ssl/openssl.cnf && \
    sed -i -e '/countryName_max/a countryName_value\t\t= US' /etc/ssl/openssl.cnf && \
    mkdir -p /var/lib/pritunl

# Copy init script (исправлено: явное копирование)
COPY init.sh /init
RUN chmod +x /init

EXPOSE 80 443 1194/tcp 1194/udp 1195/udp

ENTRYPOINT ["/init"]