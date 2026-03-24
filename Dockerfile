FROM continuumio/miniconda3:24.1.2-0

WORKDIR /workspace/DR-MPC

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    cmake \
    ffmpeg \
    git \
    && rm -rf /var/lib/apt/lists/*

COPY . /workspace/DR-MPC

RUN conda env create -f environment.yml && conda clean -afy

RUN git clone https://github.com/sybrenstuvel/Python-RVO2.git /workspace/Python-RVO2 && \
    /opt/conda/bin/conda run -n social_navigation bash -lc "cd /workspace/Python-RVO2 && python setup.py build && python setup.py install"

RUN git clone https://github.com/utiasASRL/pysteam.git /workspace/pysteam

ENV PYTHONPATH=/workspace/DR-MPC:/workspace/pysteam

CMD ["bash"]
