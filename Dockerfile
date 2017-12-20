FROM alpine:3.7

RUN apk add --no-cache build-base git meson

WORKDIR /src
RUN git clone --depth 5 -b add-meson https://github.com/jibsen/brieflz.git
WORKDIR brieflz/build
RUN meson .. && ninja && ninja test
