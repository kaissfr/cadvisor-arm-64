FROM golang:1.13-alpine 

ENV GOPATH /go
ENV CGO_ENABLED 0
ENV GO111MODULE on


RUN apk add --no-cache --virtual .build-deps gcc git make bash libc-dev
RUN go get github.com/google/cadvisor 
RUN mv $GOPATH/bin/cadvisor /cadvisor 
RUN apk del .build-deps

# reference : https://github.com/google/cadvisor/blob/master/deploy/Dockerfile
FROM arm64v8/alpine:3.11

RUN apk --no-cache add libc6-compat device-mapper findutils && \
    apk --no-cache add zfs || true && \
    apk --no-cache add thin-provisioning-tools --repository http://dl-3.alpinelinux.org/alpine/edge/main/ && \
    echo 'hosts: files mdns4_minimal [NOTFOUND=return] dns mdns4' >> /etc/nsswitch.conf && \
    rm -rf /var/cache/apk/*

COPY --from=0 /cadvisor /usr/bin/cadvisor

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s \
  CMD wget --quiet --tries=1 --spider http://localhost:8080/healthz || exit 1

ENTRYPOINT ["/usr/bin/cadvisor", "-logtostderr"]
