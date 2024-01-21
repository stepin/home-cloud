FROM ghcr.io/grishy/go-avahi-cname:v2.0.2 as go-avahi-cname

FROM python:3-alpine
RUN apk --no-cache add avahi avahi-tools bash
COPY --from=go-avahi-cname /go-avahi-cname /app/
COPY *.py /app/
COPY *.sh /app/
