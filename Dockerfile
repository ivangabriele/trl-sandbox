# https://huggingface.co/docs/hub/spaces-dev-mode#docker-spaces

FROM python:3.13-bookworm

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

RUN wget https://developer.download.nvidia.com/compute/cuda/12.9.1/local_installers/cuda_12.9.1_575.57.08_linux.run
RUN sh cuda_12.9.1_575.57.08_linux.run

RUN useradd -m -u 1000 user

WORKDIR /app
RUN chown user /app
RUN chmod 755 /app

USER user
ENV PATH="/home/user/.local/bin:$PATH"
RUN curl -fsSL https://pyenv.run | bash
RUN curl -LsSf https://astral.sh/uv/install.sh | sh

COPY --chown=user . /app

RUN ls -la /app

RUN uv sync
RUN . .venv/bin/activate

# `7860` is the default port for Hugging Face Spaces running on Docker
# https://huggingface.co/docs/hub/en/spaces-config-reference
CMD ["python", "-m", "http.server", "--directory", "public", "7860"]
