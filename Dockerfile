# TARGETPLATFORM and BUILDPLATFORM are automatically filled in by Docker buildx.
# They should not be set in the global scope manually.

FROM --platform=${BUILDPLATFORM} mcr.microsoft.com/dotnet/sdk:6.0 AS builder

# Copy build context
WORKDIR /TShock
COPY . ./

# Build and package release based on target architecture
RUN dotnet build -v m
WORKDIR /TShock/TShockLauncher

# Make TARGETPLATFORM available to the container.
ARG TARGETPLATFORM

RUN \ 
  case "${TARGETPLATFORM}" in \
    "linux/amd64") export ARCH="linux-x64" \
    ;; \
    "linux/arm64") export ARCH="linux-arm64" \
    ;; \
    "linux/arm/v7") export ARCH="linux-arm" \
    ;; \
    "windows/amd64") export ARCH="win-x64" \
    ;; \
    *) echo "Error: Unsupported platform ${TARGETPLATFORM}" && exit 1 \
    ;; \
  esac && \
  dotnet publish -o output/ -r "${ARCH}" -v m -f net9.0 -c Release -p:PublishSingleFile=true --self-contained false

# Runtime image
FROM --platform=${TARGETPLATFORM} mcr.microsoft.com/dotnet/runtime:6.0 AS runner
WORKDIR /server
COPY --from=builder /TShock/TShockLauncher/output ./

VOLUME ["/tshock", "/worlds", "/plugins"]
EXPOSE 7777 7878

ENTRYPOINT [ \
  "./TShock.Server", \
  "-configpath", "/tshock", \
  "-logpath", "/tshock/logs", \
  "-crashdir", "/tshock/crashes", \
  "-worldselectpath", "/worlds", \
  "-additionalplugins", "/plugins" \
]
