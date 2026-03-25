# Docker 설치 스크립트 추가 작업 요약

## 작업 내용

Docker CE, Docker Compose 플러그인, NVIDIA 컨테이너 런타임을 현재 환경과 동일하게 설치하는 스크립트를 추가했습니다.

## 생성/수정된 파일

### 새로 생성

| 파일 | 설명 |
|------|------|
| `configs/docker-daemon.json` | NVIDIA 런타임 설정 (`/etc/docker/daemon.json` 복제) |
| `scripts/install-docker.sh` | Docker CE + Compose + Buildx 설치, 그룹 설정, daemon.json 배포 |
| `tests/test-docker.sh` | Docker 설치 검증 테스트 (13개 어설션) |

### 수정

| 파일 | 변경 내용 |
|------|-----------|
| `install.sh` | Docker 스텝 추가 (`--skip-docker` 플래그 포함) |
| `README.md` | Docker 섹션, 설치 명령, 옵션, 테스트, 구조 업데이트 |

## install-docker.sh 동작

1. **APT 저장소 설정**: Docker 공식 GPG 키 + DEB822 형식 소스 파일 (Ubuntu 24.04+)
2. **패키지 설치**: `docker-ce`, `docker-ce-cli`, `containerd.io`, `docker-buildx-plugin`, `docker-compose-plugin`
3. **사용자 그룹**: 현재 사용자를 `docker` 그룹에 추가
4. **daemon.json 배포**: NVIDIA 런타임 설정 복사 (기존 설정과 다르면 백업 후 덮어쓰기)
5. **서비스 활성화**: systemd로 Docker 서비스 enable + start
6. **설치 검증**: docker, docker compose 버전 확인

## 테스트 결과

```
6개 테스트 스위트 전체 통과 (45개 어설션)

- test-dependencies: 6/6
- test-docker: 13/13
- test-ghostty: 2/2
- test-omo: 16/16
- test-opencode: 4/4
- test-shell: 4/4
```

## 복제되는 Docker 환경

- Docker CE v29.1.3 (공식 APT 저장소)
- Docker Compose v5.0.0 (플러그인)
- Docker Buildx (멀티 플랫폼 빌드)
- NVIDIA Container Runtime (`nvidia-container-runtime`)
- overlayfs 스토리지 드라이버
- `docker` 그룹으로 sudo 없이 실행
