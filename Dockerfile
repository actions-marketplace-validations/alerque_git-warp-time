#syntax=docker/dockerfile:1.2

FROM alpine:3.19.0 AS builder
RUN apk add --no-cache build-base rustup

COPY ./ /src
WORKDIR /src

RUN rustup-init --default-toolchain=stable -y
ENV PATH="$PATH:/root/.cargo/bin"
RUN cargo fetch --target x86_64-unknown-linux-musl --locked
RUN cargo build --frozen --release

FROM alpine:3.19.0 AS runtime

RUN apk add --no-cache git

# Everything inside this container will be explicitly mounted by the end user,
# so we can sidestep some Git security restrictions. This app recommends
# mounting data to /app, but this *can* be changed externally and *will* be
# changed when run by GitHub Actions, so we need to cover our bases.
RUN echo '[safe]\n\tdirectory = *' > /etc/gitconfig

LABEL org.opencontainers.image.title="Git Warp Time"
LABEL org.opencontainers.image.description="A containerized version of Git Wark Time"
LABEL org.opencontainers.image.authors="Caleb Maclennan <caleb@alerque.com>"
LABEL org.opencontainers.image.licenses="GPL-3.0"
LABEL org.opencontainers.image.url="https://github.com/alerque/git-warp-time/pkgs/container/git-warp-time"
LABEL org.opencontainers.image.source="https://github.com/alerque/git-warp-time"

COPY --from=builder /src/target/release/git-warp-time /usr/local/bin
RUN git-warp-time --version

WORKDIR /data

ENTRYPOINT ["git-warp-time"]
