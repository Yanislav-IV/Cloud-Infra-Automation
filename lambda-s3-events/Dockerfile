# Stage 1: Prepare the environment and install dependencies
FROM amazonlinux:2 as builder

# Install pip and other necessary packages
RUN yum update -y && \
    yum install -y python3-pip && \
    yum clean all && \
    rm -rf /var/cache/yum

# Set the working directory
WORKDIR /app

# Copy the requirements file to the working directory
COPY requirements.txt .

# Install Python dependencies into the /app directory
RUN pip3 install --no-cache-dir --target /app -r requirements.txt

# Copy the function code into the /app directory
COPY s3_events.py /app/

# Stage 2: Create the final runtime image
FROM amazonlinux:2

# Install Python and shadow-utils for user management
RUN yum install -y python3 shadow-utils && \
    yum clean all && \
    rm -rf /var/cache/yum

# Install AWS Lambda Runtime Interface Client
RUN pip3 install awslambdaric

# Set the working directory
WORKDIR /app

# Copy the dependencies and function code from the builder stage to the working directory
COPY --from=builder /app /app

# Create a non-root user and change ownership of the /app directory
RUN useradd -m lambdauser && \
    chown -R lambdauser:lambdauser /app

# Switch to the non-root user
USER lambdauser

# Set the entrypoint and command for the Lambda function using awslambdaric
ENTRYPOINT ["python3", "-m", "awslambdaric"]
CMD ["s3_events.lambda_handler"]
