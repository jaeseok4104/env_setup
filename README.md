# env_setup

OpenCode + OMO (Oh-My-OpenCode) + Ghostty + Docker 환경 설정 자동화 스크립트.

새로운 Ubuntu 시스템에서 현재 개발 환경을 그대로 재현합니다.

## 설치하는 것들

| 도구 | 설명 | 설치 방식 |
|------|------|-----------|
| **OpenCode** | AI 코딩 에이전트 | GitHub Release 바이너리 |
| **OMO** | OpenCode 멀티모델 오케스트레이션 플러그인 | npm (opencode 플러그인) |
| **Ghostty** | GPU 가속 터미널 에뮬레이터 | snap |
| **Docker** | 컨테이너 런타임 + Compose | Docker 공식 APT 저장소 |

## 빠른 시작

```bash
git clone <this-repo> ~/env_setup
cd ~/env_setup
./install.sh
```

## 개별 설치

```bash
./scripts/install-dependencies.sh   # bun, node, snap 등 사전 의존성
./scripts/install-opencode.sh       # opencode 바이너리 + 플러그인 런타임
./scripts/install-omo.sh            # OMO 설정 파일 배포 + 플러그인 설치
./scripts/install-ghostty.sh        # Ghostty 터미널
./scripts/install-docker.sh         # Docker CE + Compose + NVIDIA 런타임
./scripts/setup-shell.sh            # PATH 설정 (~/.bashrc에 추가)
```

## 옵션

```bash
./install.sh --force          # 기존 설정 파일 덮어쓰기
./install.sh --dry-run        # 실제 실행 없이 계획만 출력
./install.sh --skip-ghostty   # Ghostty 설치 건너뛰기
./install.sh --skip-docker    # Docker 설치 건너뛰기
./install.sh --skip-deps      # 의존성 설치 건너뛰기
./install.sh --skip-opencode  # OpenCode 설치 건너뛰기
./install.sh --skip-omo       # OMO 설치 건너뛰기
./install.sh --skip-shell     # 셸 설정 건너뛰기
```

## 테스트

```bash
./tests/test-all.sh           # 전체 테스트
./tests/test-dependencies.sh  # 의존성만 확인
./tests/test-opencode.sh      # opencode만 확인
./tests/test-omo.sh           # OMO만 확인
./tests/test-ghostty.sh       # Ghostty만 확인
./tests/test-docker.sh        # Docker만 확인
./tests/test-shell.sh         # 셸 설정만 확인
```

## OMO 프로필

| 프로필 | 파일 | 설명 |
|--------|------|------|
| **기본 (Copilot)** | `oh-my-opencode.json` | GitHub Copilot 모델 (gpt-5.4, claude-opus-4.6 등) |
| **Copilot 백업** | `oh-my-opencode-copilot.json` | 기본과 동일 |
| **Full OpenAI** | `oh-my-opencode.full.json` | OpenAI 직접 연결 (gpt-5.4, gpt-5.3-codex) |
| **Spark** | `oh-my-opencode.spark.json` | 경량 프로필 (gpt-5.3-codex-spark) |

## Docker 설정

| 구성 요소 | 설명 |
|-----------|------|
| **Docker CE** | Docker 공식 APT 저장소에서 설치 |
| **Docker Compose** | v2 플러그인 (`docker compose`) |
| **Docker Buildx** | 멀티 플랫폼 빌드 플러그인 |
| **NVIDIA Runtime** | `nvidia-container-runtime` 설정 (`daemon.json`) |

Docker 그룹에 현재 사용자를 추가하여 `sudo` 없이 Docker 명령을 실행할 수 있습니다.
그룹 변경 적용을 위해 로그아웃 후 다시 로그인이 필요할 수 있습니다.

## 설치 후 수동 설정

스크립트는 인증 정보를 포함하지 않습니다. 설치 후 직접 설정해야 합니다:

1. `opencode` 실행 후 GitHub Copilot 인증
2. (선택) OpenAI API 키 설정
3. (선택) Google Antigravity 인증 설정

## 구조

```
env_setup/
├── install.sh                  # 마스터 설치 스크립트
├── scripts/
│   ├── _common.sh              # 공통 유틸 함수
│   ├── install-dependencies.sh # 사전 의존성
│   ├── install-opencode.sh     # OpenCode
│   ├── install-omo.sh          # OMO
│   ├── install-ghostty.sh      # Ghostty
│   ├── install-docker.sh       # Docker CE + Compose
│   └── setup-shell.sh          # 셸 환경 설정
├── configs/
│   ├── opencode.json
│   ├── oh-my-opencode.json
│   ├── oh-my-opencode-copilot.json
│   ├── oh-my-opencode.full.json
│   └── oh-my-opencode.spark.json
├── configs/
│   └── docker-daemon.json
└── tests/
    ├── _helpers.sh
    ├── test-all.sh
    ├── test-dependencies.sh
    ├── test-opencode.sh
    ├── test-omo.sh
    ├── test-ghostty.sh
    ├── test-docker.sh
    └── test-shell.sh
```
