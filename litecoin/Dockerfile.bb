# Stage 1: Prepare the environment
FROM amazonlinux:2 as builder

# Copy the pre-compiled litecoind binary to the appropriate location
COPY build/litecoind /usr/local/bin/litecoind

# Ensure the litecoind binary is executable
RUN chmod +x /usr/local/bin/litecoind

# Stage 2: Create the final runtime image
FROM busybox:1.36-glibc

# Create a user group and user for running the application
RUN addgroup -S litecoin && adduser -S -G litecoin litecoin

# Create a directory for Litecoin data and set the appropriate permissions
RUN mkdir -p /home/litecoin && chown litecoin:litecoin /home/litecoin

# Copy necessary shared libraries from the builder stage
COPY --from=builder /lib64/libgcc_s.so.1 \
                    /lib64/ld-linux-x86-64.so.2 \
                    /lib64/libm.so.6 \
                    /lib64/libpthread.so.0 \
                    /lib64/libc.so.6  \
                    /lib64/librt.so.1 \
                    /lib/

# Copy the litecoind binary from the builder stage
COPY --from=builder /usr/local/bin/litecoind /usr/local/bin/

# Set the working directory and switch to the non-root user
WORKDIR /home/litecoin
USER litecoin

# Start the Litecoin daemon and print logs to the console
CMD ["/usr/local/bin/litecoind", "-printtoconsole"]
