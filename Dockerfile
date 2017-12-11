FROM nimlang/nim:alpine AS builder
COPY src .
RUN nimble install jester -y
RUN nim c -d:release app.nim

FROM alpine
RUN apk add --no-cache libpq
RUN mkdir /meters
WORKDIR /meters
COPY --from=builder app .
COPY public ./public
EXPOSE 5000
CMD ["./app"]