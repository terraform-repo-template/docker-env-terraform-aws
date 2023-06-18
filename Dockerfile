# Reference: https://stackoverflow.com/questions/60298619/awscli-version-2-on-alpine-linux
ARG ALPINE_VERSION=3.17.3
ARG PYTHON_VERSION=3.11.3-alpine3.17

FROM python:${PYTHON_VERSION} as builder

# https://github.com/aws/aws-cli/tags
ARG AWS_CLI_VERSION
ARG TERRAFORM_VERSION

ARG TARGETPLATFORM

RUN apk add --update --no-cache \
      git \
      unzip \
      groff \
      build-base \
      libffi-dev \
      cmake \
      curl \
      bash \
      openssl \
      ca-certificates \
      jq \
      openssh \
      go

RUN git clone --single-branch --depth 1 -b ${AWS_CLI_VERSION} https://github.com/aws/aws-cli.git

WORKDIR /aws-cli
RUN python -m venv venv
RUN . venv/bin/activate
RUN scripts/installers/make-exe
RUN unzip -q dist/awscli-exe.zip
RUN aws/install --bin-dir /aws-cli-bin 
RUN /aws-cli-bin/aws --version

# reduce image size: remove autocomplete and examples
RUN rm -rf /usr/local/aws-cli/v2/current/dist/aws_completer /usr/local/aws-cli/v2/current/dist/awscli/data/ac.index /usr/local/aws-cli/v2/current/dist/awscli/examples
RUN find /usr/local/aws-cli/v2/current/dist/awscli/botocore/data -name examples-1.json -delete

# Install Terraform
RUN TARGETPLATFORM_UNDERSCORE=$(echo "$TARGETPLATFORM" | sed 's/\//_/g') && \
    cd /usr/local/bin && \
    curl https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_${TARGETPLATFORM_UNDERSCORE}.zip -o terraform_${TERRAFORM_VERSION}_${TARGETPLATFORM_UNDERSCORE}.zip && \
    unzip terraform_${TERRAFORM_VERSION}_${TARGETPLATFORM_UNDERSCORE}.zip && \
    rm terraform_${TERRAFORM_VERSION}_${TARGETPLATFORM_UNDERSCORE}.zip

# install go app - tf-summarize
RUN go install github.com/dineshba/tf-summarize@latest

FROM alpine:${ALPINE_VERSION}

RUN apk update && apk upgrade --no-cache

RUN apk add --update --no-cache \
      git \
      zip \
      unzip \
      groff \
      curl \
      bash \
      openssl \
      ca-certificates \
      jq \
      openssh \
      sed \
      shellcheck

COPY --from=builder /usr/local/aws-cli/ /usr/local/aws-cli/
COPY --from=builder /aws-cli-bin/ /usr/local/bin/

COPY --from=builder /usr/local/bin/terraform /usr/local/bin/terraform

COPY --from=builder /root/go/bin/tf-summarize /usr/local/bin/tf-summarize

# add a non-root user
RUN addgroup -g 1000 user && \
    adduser -D -u 1000 user -G user

USER user:user

HEALTHCHECK CMD terraform version || exit 1