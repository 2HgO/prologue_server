FROM nimlang/nim:1.6.0-alpine-regular

RUN mkdir -p /app

WORKDIR /app

COPY prologue_server.nimble .

RUN nimble install -d -y

COPY . .

RUN apk add --no-cache bsd-compat-headers
RUN apk add --no-cache pcre-dev

RUN nimble build --silent

ENTRYPOINT [ "./prologue_server" ]
