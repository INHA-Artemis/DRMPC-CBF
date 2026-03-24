# DR-MPC Guide-Dog / VIP Simulator

이 저장소는 original DR-MPC project를 기반으로 수정한 버전입니다. 핵심 확장점은 guide-dog와 visually impaired person(VIP)을 하나의 pair로 시뮬레이션하는 기능이며, harness dynamics, pair-aware safety check, 그리고 richer video visualization을 추가한 것입니다.

## Original Reference

- Original DR-MPC repository: https://github.com/James-R-Han/DR-MPC
- Paper: https://arxiv.org/abs/2410.10646
- IEEE publication: https://ieeexplore.ieee.org/document/10904316

## Demo Video

GitHub 환경에 따라 inline rendering이 보이지 않을 수 있습니다. 그런 경우 아래 링크로 직접 열면 됩니다.

<video src="docs/media/vid_0.mp4" controls width="900"></video>

[Open demo video](docs/media/vid_0.mp4)

## What This Simulator Does

이 simulator는 아래 두 subsystem을 결합합니다.

1. Human avoidance (HA): the dog must move safely through nearby pedestrians.
2. Path tracking (PT): the dog must still stay inside the target corridor and progress toward the goal.

수정된 버전에서는 dog를 단독 agent로 보지 않고, dog의 right-rear 쪽에 VIP agent가 harness model로 연결된 상태를 함께 시뮬레이션합니다. 매 step마다 VIP state를 갱신하고, dog와 VIP 모두에 대해 safety를 검사하며, recorded video에는 두 agent와 harness 정보가 함께 표시됩니다.

## Repository Layout

- `environment/`: simulator environment 코드
- `scripts/`: training, policy, model, config 코드
- `configs/guide_dog_params.yaml`: guide-dog / VIP simulator parameter 파일
- `docs/media/vid_0.mp4`: README에서 보여주는 demo video

## Local Installation

### 1. Clone this repository

```bash
git clone https://github.com/INHA-Artemis/DRMPC-HRI.git
cd DRMPC-HRI
```

### 2. Create the conda environment

```bash
conda env create -f environment.yml
conda activate social_navigation
```

사용 중인 machine의 CUDA 또는 Torch 버전이 다르면 `environment.yml` 안의 Torch 관련 package를 맞게 조정해서 설치하면 됩니다.

### 3. Install system packages

```bash
sudo apt update
sudo apt install -y build-essential cmake ffmpeg git
```

위 package는 Python-RVO2 build, video generation, Git clone에 필요합니다.

### 4. Install Python-RVO2

```bash
git clone https://github.com/sybrenstuvel/Python-RVO2.git
cd Python-RVO2
python setup.py build
python setup.py install
cd ..
```

### 5. Install pysteam

```bash
git clone https://github.com/utiasASRL/pysteam.git
```

`pysteam`은 repository root 바깥에 있어도 되지만, 가장 단순하게는 현재 작업 위치에 같이 clone해서 사용하면 됩니다.

### 6. Set `PYTHONPATH`

```bash
export PYTHONPATH="${PYTHONPATH}:$(pwd)"
```

현재 repository root를 `PYTHONPATH`에 추가해서 local package import가 가능하도록 맞춰줍니다.

## Run The Code

학습과 simulator 실행은 아래 command로 시작합니다.

```bash
python scripts/online_continuous_task.py
```

여러 run 결과 비교는 아래 command를 사용합니다.

```bash
python scripts/compare_training_multirun.py
```

생성된 video와 plot은 일반적으로 `HA_and_PT_results/` 아래에 저장됩니다.

## Docker Installation

이 fork에는 Docker setup도 포함되어 있습니다. 아래 설정은 container 내부 working directory가 반드시 `/workspace/DR-MPC`가 되도록 맞췄습니다.

### 1. Build the image

```bash
docker build -t drmpc-hri .
```

### 2. Run the training script inside Docker

```bash
docker run --rm -it \
  -v "$(pwd)":/workspace/DR-MPC \
  -w /workspace/DR-MPC \
  drmpc-hri \
  conda run --no-capture-output -n social_navigation python scripts/online_continuous_task.py
```

위 command로 실행하면 container 내부에서 `pwd` 결과가 `/workspace/DR-MPC`가 됩니다.

### 3. Open an interactive shell inside Docker

```bash
docker run --rm -it \
  -v "$(pwd)":/workspace/DR-MPC \
  -w /workspace/DR-MPC \
  drmpc-hri \
  bash
```

interactive shell 안에서 아래처럼 확인할 수 있습니다.

```bash
pwd
# /workspace/DR-MPC
```

GPU를 사용하려면 NVIDIA 환경에서 `--gpus all` 같은 runtime option을 추가하면 됩니다.

## What Was Modified

### Core Python files

- `environment/human_avoidance/subENVs/crowd_sim.py`
  - separate VIP agent를 추가했습니다.
  - harness tension, VIP offset 같은 guide-pair state를 추가했습니다.
  - VIP synchronization과 harness-dynamics update logic를 추가했습니다.
  - gait variability, heading smoothing, no-backward motion constraint, pair-length constraint를 추가했습니다.
  - human spawning과 ORCA-style avoidance check가 dog뿐 아니라 VIP도 고려하도록 확장했습니다.

- `environment/human_avoidance/human_avoidance_env.py`
  - 저속에서 in-place turning을 줄이기 위한 `no_pivot` option을 추가했습니다.
  - dog가 움직인 뒤 VIP state를 바로 갱신하도록 step logic를 수정했습니다.
  - collision 및 minimum-distance check를 dog-only에서 dog-or-VIP 기준으로 확장했습니다.
  - episode reset 시 VIP pose가 dog 기준으로 동기화되도록 바꿨습니다.

- `environment/HA_and_PT/human_avoidance_and_path_tracking_env.py`
  - recorded trajectory에 VIP state를 함께 저장하도록 했습니다.
  - VIP 기준 path-corridor penalty와 safety-corridor penalty를 추가했습니다.
  - soft-reset 중에는 no-pivot constraint를 완화하도록 했습니다.
  - orange VIP circle과 harness line을 rendering에 추가했습니다.
  - dog speed, VIP speed, VIP acceleration, harness roll angle, harness tension overlay를 video에 표시하도록 했습니다.

- `scripts/configs/config_HA.py`
  - `configs/guide_dog_params.yaml`에서 parameter를 읽도록 YAML loading을 추가했습니다.
  - pair geometry, tension, gait, rendering setting을 담는 `guide` configuration block을 추가했습니다.

- `scripts/configs/config_training.py`
  - `save_freq`를 `50 * 250`에서 `10 * 250`으로 줄여 intermediate result를 더 자주 저장하도록 했습니다.

- `scripts/online_continuous_task.py`
  - non-GUI 환경에서도 동작하도록 headless Matplotlib backend `Agg`를 강제했습니다.
  - warm-up 조건과 batch-size 조건을 동시에 만족할 때만 training update가 시작되도록 수정했습니다.

- `scripts/models/utils.py`
  - GRU forward pass를 정리하고 encoding 전에 `flatten_parameters()`를 호출하도록 바꿔 warning을 줄이고 cuDNN compatibility를 개선했습니다.

### Added support files

- `configs/guide_dog_params.yaml`
  - guide-dog / VIP simulator parameter를 YAML로 분리해 한 곳에서 조정할 수 있게 했습니다.

- `requirements_pip.txt`
  - conda 대신 pip 기반으로 설치하고 싶을 때 사용할 수 있도록 requirements list를 추가했습니다.

- `docs/media/vid_0.mp4`
  - README에서 바로 볼 수 있도록 tracked demo video를 추가했습니다.

## How The Modified Simulator Works

매 simulation step은 대략 아래 순서로 진행됩니다.

1. dog가 navigation action을 받습니다.
2. HA environment가 저속에서 과도한 in-place pivoting을 줄입니다.
3. VIP는 independent navigation policy가 아니라 simplified harness-following model로 움직입니다.
4. human avoidance safety는 dog-VIP pair 전체 기준으로 검사됩니다.
5. dog 또는 VIP가 corridor를 벗어나면 path tracking penalty가 적용됩니다.
6. video logging에는 trajectory와 diagnostic value가 함께 저장됩니다.

## Guide-Dog Parameter Summary

pair 관련 parameter는 모두 `configs/guide_dog_params.yaml`에 들어 있습니다.

- `enable_pair`: dog-VIP pair model 사용 여부
- `vip_radius`: orange VIP agent의 반지름
- `offset_right_m`, `offset_back_m`: dog 기준 VIP 기본 위치
- `offset_right_min_m`, `offset_back_min_m`: VIP가 right-rear 쪽에 남도록 하는 최소 제한값
- `rod_length_m`, `rod_angle_deg_min`, `rod_angle_deg_max`: projected harness length 범위를 정하는 값
- `person_mass_kg`: simplified harness model에서 사용하는 VIP 질량
- `spring_k`, `damping_c`: harness tension 계산용 spring-damper coefficient
- `max_tension_n`, `min_tension_n`: tension의 상한과 하한
- `min_pair_clearance_m`: dog와 VIP 사이 추가 clearance
- `max_pull_step_m`: 한 step에서 적용할 최대 pull 거리
- `follow_gain`: VIP가 dog-side anchor를 따라가는 강도
- `vip_speed_max_mps`, `vip_acc_max_mps2`: VIP speed / acceleration 제한
- `heading_tau_s`: VIP heading alignment를 얼마나 부드럽게 할지 결정하는 time constant
- `dog_no_pivot_min_v_mps`: 저속 pivot 억제에 사용하는 속도 threshold
- `vip_gait_*`: stride amplitude, stride frequency, gait-speed variation 관련 parameter들

## Notes

- 이 fork는 paired simulator logic를 문서화하고 공개한 버전이며, original DR-MPC paper나 upstream implementation 자체를 대체하지는 않습니다.
- 이 fork를 사용할 때에도 original DR-MPC project에 대한 credit은 유지하는 것이 좋습니다.
