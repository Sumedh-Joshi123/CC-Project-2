# Define global args
# ARG FUNCTION_DIR="/tmp/"
# ARG FUNCTION_DIR=${LAMBDA_TASK_ROOT}
# ARG FUNCTION_DIR="/home/app/"
ARG FUNCTION_DIR="/root/"
ARG RUNTIME_VERSION="3.8"
ARG DISTRO_VERSION="3.12"

# Stage 1 - bundle base image + runtime
# Grab a fresh copy of the image and install GCC
FROM python:${RUNTIME_VERSION} AS python-alpine
# Install GCC (Alpine uses musl but we compile and link dependencies with GCC)
#RUN apk add --no-cache \
#    libstdc++

RUN apt-get update \
    && apt-get install -y cmake ca-certificates libgl1-mesa-glx
RUN python${RUNTIME_VERSION} -m pip install --upgrade pip

# Stage 2 - build function and dependencies
FROM python-alpine AS build-image
# Install aws-lambda-cpp build dependencies
#RUN apk add --no-cache \
#    build-base \
#    libtool \
#    autoconf \
#    automake \
#    libexecinfo-dev \
#    make \
#    cmake \
#    libcurl
# Include global args in this stage of the build
ARG FUNCTION_DIR
ARG RUNTIME_VERSION
# Create function directory
RUN mkdir -p ${FUNCTION_DIR}

# Optional – Install the function's dependencies
# RUN python${RUNTIME_VERSION} -m pip install -r requirements.txt --target ${FUNCTION_DIR}
# Install Lambda Runtime Interface Client for Python
RUN python${RUNTIME_VERSION} -m pip install awslambdaric --target ${FUNCTION_DIR}

# Stage 3 - final runtime image
# Grab a fresh copy of the Python image
FROM python-alpine
# Include global arg in this stage of the build
ARG FUNCTION_DIR
# Set working directory to function root directory
WORKDIR ${FUNCTION_DIR}
# Copy in the built dependencies
COPY --from=build-image ${FUNCTION_DIR} ${FUNCTION_DIR}
# (Optional) Add Lambda Runtime Interface Emulator and use a script in the ENTRYPOINT for simpler local runs
ADD https://github.com/aws/aws-lambda-runtime-interface-emulator/releases/latest/download/aws-lambda-rie /usr/bin/aws-lambda-rie
RUN chmod 755 /usr/bin/aws-lambda-rie

# Install ffmpeg
RUN apt-get install -y ffmpeg
RUN apt-get install -y awscli
#   aws s3 cp s3://... ...
#AWS Configure
RUN mkdir ~/.aws
# RUN --mount=type=secret,id=aws,target=/root/.aws/credentials 
# RUN cd /root/.aws/
# RUN cat credentials
# RUN aws s3 cp s3://project-2-extra/credentials ~/.aws/ 
# COPY credentials ~/.aws
# RUN aws s3 cp s3://project-2-extra/config ~/.aws/ 
# probably: created an extra s3 bucket, which stored access key csv file
#RUN aws s3 cp s3://cloud-project-input/test_case_1/test_0.mp4 /home/app/.
# COPY config ~/.aws
#COPY test_0.mp4 ${FUNCTION_DIR}
COPY encoding ${FUNCTION_DIR}

# Copy handler function
COPY requirements.txt ${FUNCTION_DIR}
RUN python${RUNTIME_VERSION} -m pip install -r requirements.txt --target ${FUNCTION_DIR}
COPY entry.sh /
# COPY encoding.dat /home/app/

# Copy function code
COPY handler.py ${FUNCTION_DIR}
RUN chmod 777 /entry.sh
# RUN chmod 777 /home/app

# Set the CMD to your handler (could also be done as a parameter override outside of the Dockerfile)
# CMD [ "handler.handler" ]
# ENTRYPOINT [ "/usr/bin/aws-lambda-rie", "/usr/local/bin/python3", "-m", "awslambdaric" ]
ENTRYPOINT [ "/entry.sh" ]
# CMD [ "frame.face_recognition_handler" ]
# ENTRYPOINT [ "/usr/local/bin/python3", "-m", "awslambdaric" ]
CMD [ "handler.face_recognition_handler" ]
