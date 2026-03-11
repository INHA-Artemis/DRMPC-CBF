FROM nvidia/cuda:12.4.1-cudnn-runtime-ubuntu20.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC
ENV PYTHONUNBUFFERED=1

RUN apt-get update -o Acquire::Retries=5 && \
    apt-get install -y -o Acquire::Retries=5 --no-install-recommends \
    software-properties-common \
    git \
    bzip2 \
    ca-certificates \
    build-essential \
    cmake \
    ffmpeg \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender-dev \
    libgl1 \
    python3.9 \
    python3.9-dev \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

RUN ln -sf /usr/bin/python3.9 /usr/bin/python && \
    ln -sf /usr/bin/python3.9 /usr/bin/python3

WORKDIR /workspace

RUN git clone https://github.com/James-R-Han/DR-MPC.git
WORKDIR /workspace/DR-MPC

COPY requirements_pip.txt /workspace/DR-MPC/requirements_pip.txt

RUN python -m pip install --upgrade pip setuptools wheel

# 1) 일반 Python 패키지 먼저
RUN pip install --no-cache-dir -r requirements_pip.txt

# 2) PyTorch CUDA 12.8 wheel 설치
# For Different GPUs, you can change the CUDA version in the index URL (e.g., cu118 for CUDA 11.8)
RUN pip install --no-cache-dir \
    torch==2.7.0 torchvision==0.22.0 torchaudio==2.7.0 \
    --index-url https://download.pytorch.org/whl/cu128

# 3) torch-geometric는 torch 뒤에 설치
RUN pip install --no-cache-dir torch-geometric

# 4) Python-RVO2 설치
RUN cd /workspace && \
    git clone https://github.com/sybrenstuvel/Python-RVO2.git && \
    cd Python-RVO2 && \
    python -m pip install --no-build-isolation -e .

RUN cd /workspace/DR-MPC && \
    git clone https://github.com/utiasASRL/pysteam.git

RUN pip install -e /workspace/DR-MPC/pysteam

RUN pip install faiss-cpu

ENV PYTHONPATH=/workspace/DR-MPC

WORKDIR /workspace/DR-MPC

CMD ["/bin/bash"]