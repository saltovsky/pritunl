FROM alpine:3.19.1
LABEL maintainer="Daniel Saltovsky <daniel@saltovsky.ru>"
ENV VERSION="1.34.4575.42"

# Разрешаем pip устанавливать пакеты в системный Python (PEP 668)
ENV PIP_BREAK_SYSTEM_PACKAGES=1

# Установка всех зависимостей
RUN apk --no-cache add --update \
    go git breezy wget \
    python3 py3-pip py3-setuptools py3-wheel \
    gcc python3-dev make musl-dev linux-headers \
    libffi-dev openssl-dev \
    py3-dnspython py3-requests py3-six \
    openssl procps ca-certificates \
    openvpn iptables ip6tables ipset bash netcat-openbsd

# Установка Go
COPY --from=golang:1.22-alpine /usr/local/go/ /usr/local/go/
ENV PATH="/usr/local/go/bin:${PATH}"

# Установка утилит Pritunl (DNS и Web)
RUN go install github.com/pritunl/pritunl-dns@latest && \
    go install github.com/pritunl/pritunl-web@latest && \
    cp $HOME/go/bin/* /usr/bin/

# Установка Pritunl через pip (корректно регистрирует метаданные и зависимости)
RUN wget -q https://github.com/pritunl/pritunl/archive/refs/tags/${VERSION}.tar.gz && \
    tar xf ${VERSION}.tar.gz && \
    cd pritunl-${VERSION} && \
    pip install --no-cache-dir . && \
    # bson — это часть pymongo, ставим явно
    pip install --no-cache-dir pymongo && \
    cd .. && \
    rm -rf ${VERSION} ${VERSION}.tar.gz

# Настройка OpenSSL для генерации сертификатов
RUN sed -i -e '/^attributes/a prompt\t\t\t= yes' /etc/ssl/openssl.cnf && \
    sed -i -e '/countryName_max/a countryName_value\t\t= US' /etc/ssl/openssl.cnf && \
    mkdir -p /var/lib/pritunl

# Копирование скрипта инициализации
COPY init.sh /init
RUN chmod +x /init

EXPOSE 80 443 1194/tcp 1194/udp 1195/udp

ENTRYPOINT ["/init"]