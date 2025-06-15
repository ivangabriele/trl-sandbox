# https://huggingface.co/docs/hub/en/spaces-sdks-docker-first-demo#create-the-dockerfile

FROM nvidia/cuda:12.9.0-cudnn-runtime-ubuntu24.04

ENV RUNNING_IN_DOCKER true

RUN apt-get update
RUN apt-get install -y \
  bash \
  curl \
  git \
  git-lfs \
  htop \
  procps \
  nano \
  vim \
  wget
RUN rm -fr /var/lib/apt/lists/*

RUN useradd -m -u 1000 user

WORKDIR /app
RUN chown user /app
RUN chmod 755 /app

USER user
ENV PATH="/home/user/.local/bin:$PATH"
RUN sh -c "$(wget -O- https://github.com/deluan/zsh-in-docker/releases/download/v1.2.1/zsh-in-docker.sh)"
RUN curl -LsSf https://astral.sh/uv/install.sh | sh

COPY --chown=user . /app

RUN ls -la /app

ENV UV_NO_CACHE="1"
RUN uv venv
RUN uv sync

SHELL ["/usr/bin/bash", "-c"]

# `7860` is the default port for Hugging Face Spaces running on Docker
# https://huggingface.co/docs/hub/en/spaces-config-reference
CMD ["python", "-m", "http.server", "--directory", "public", "7860"]
