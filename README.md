Pritunl Server

1. Склонировать репозиторий: git clone https://github.com/saltovsky/pritunl.git
2. Перейти в папку проекта: cd pritunl
3. Запустить сборку образа: docker compose build --no-cache
4. Запустить контейнеры: docker compose up -d
5. Сбросить пароль пользователя pritunl: docker compose exec -i pritunl pritunl default-password