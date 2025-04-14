# 웹 오디오 알람 타이머 앱 (Web Audio Alarm Timer App)

이 앱은 웹 환경에서 안정적으로 작동하는 알람 타이머 앱입니다. 특히 iOS Safari를 포함한 모든 브라우저에서 백그라운드 타이머와 오디오 재생이 가능하도록 설계되었습니다. Flutter 웹을 기반으로 하며, 모바일 환경에서도 PWA(Progressive Web App)로 설치하여 사용할 수 있습니다.

## 데모

실제 동작하는 앱은 다음 링크에서 확인할 수 있습니다:
[https://woodyalmond.github.io/alarmapp/](https://woodyalmond.github.io/alarmapp/)


## 주요 기능

- **타이머 기능**
  - 사용자 정의 타이머 간격 설정 (분 단위)
  - 직접 시간 입력 가능한 다이얼로그
  - 심플한 프로그레스 바 UI로 남은 시간 표시
  - 백그라운드에서도 작동하는 타이머 (화면이 꺼져도 작동)

- **알람 시스템**
  - 모든 브라우저에서 안정적인 오디오 재생
  - 진동 알림 (지원 기기에서)
  - 화면 깨우기 기능

- **활동 관리**
  - 현재 활동 기록 및 관리
  - 활동 내용, 카테고리, 시간, 날짜 수정 가능
  - 시간별 활동 히트맵 시각화
  - 날짜별 활동 목록 보기

- **할일(Todo) 관리**
  - 할일 목록 생성 및 관리
  - 스와이프로 삭제 기능
  - 날짜별 할일 관리
  - 활동 기록과 연동

## 기술적 특징

### 웹 오디오 시스템
- **Web Audio API 직접 사용**
  - AudioContext를 활용한 무음 오디오 생성
  - 외부 MP3 파일 의존성 제거
  - 볼륨 조절을 통한 무음 재생
- **안정적인 오디오 초기화**
  - Promise 없는 직접 함수 호출 방식
  - 각 단계별 null 체크 및 오류 처리
  - 사용자 상호작용 시 오디오 컨텍스트 재개
- **다양한 브라우저 환경 지원**
  - iOS Safari 호환성 확보
  - 오류 발생 시 대체 경로 제공
  - 다중 알림 전략(오디오+진동+알림)

### 백그라운드 타이머
- **Web Worker 기반 구현**
  - 메인 스레드와 독립적으로 작동
  - 100ms 간격으로 타이머 상태 업데이트
  - 타이머 완료 시 자동 알람 재생
- **상태 관리**
  - 로컬 스토리지 기반 타이머 상태 추적
  - 워커와 메인 스레드 간 상태 동기화
  - 타임스탬프 기반 동기화로 정확성 향상
- **성능 최적화**
  - 업데이트 빈도 감소를 통한 배터리 절약
  - 이벤트 제한을 통한 성능 향상

### 화면 켜짐 유지
- **Wake Lock API 통합**
  - 화면 꺼짐 방지 기능
  - 해제 시 자동으로 다시 요청하는 메커니즘
  - 가시성 변경 이벤트 처리

### 강화된 진동 패턴
- **진동 API 통합**
  - 더 강력하고 길어진 진동 패턴 (500ms ON, 100ms OFF)
  - 진동 자동 반복 기능 (총 3회)
  - 진동 API 호출 시 오류 처리 강화

## 설치 및 개발 환경 설정

### 필요 조건
- Flutter SDK 3.0.0 이상
- Dart 2.17.0 이상
- 웹 개발을 위한 Chrome 또는 Edge 브라우저

### 개발 환경 설정
1. Flutter SDK를 설치합니다:
   ```
   https://flutter.dev/docs/get-started/install
   ```

2. 저장소를 클론합니다:
   ```
   git clone https://github.com/woodyalmond/alarmapp.git
   cd alarmapp
   ```

3. 의존성 패키지를 설치합니다:
   ```
   flutter pub get
   ```

4. 개발 모드로 앱을 실행합니다:
   ```
   flutter run -d chrome
   ```

## 웹 빌드 및 배포

### GitHub Pages 배포
웹 버전을 빌드하고 GitHub Pages에 배포하려면:

```bash
# 웹 빌드 생성
flutter build web --base-href /alarmapp/ --release

# 배포 디렉토리로 이동
cd build/web

# Jekyll 처리 방지 파일 생성
New-Item -Path ".nojekyll" -ItemType File -Force

# Git 저장소 초기화 및 커밋
git init
git add .
git commit -m "Deploy to GitHub Pages"

# gh-pages 브랜치 생성 및 푸시
git branch -M gh-pages
git remote add origin https://github.com/woodyalmond/alarmapp.git
git push -f origin gh-pages
```

### 로컬 웹 서버 실행
로컬에서 빌드된 웹 앱을 테스트하려면:

```bash
# 웹 빌드 생성
flutter build web --release

# 간단한 웹 서버 실행 (Python 사용)
cd build/web
python -m http.server 8000
```
그런 다음 브라우저에서 `http://localhost:8000`으로 접속하여 앱을 확인할 수 있습니다.

## 앱 아키텍처

### MVVM 아키텍처
이 앱은 MVVM (Model-View-ViewModel) 아키텍처 패턴을 따릅니다:

- **Models**: 데이터 구조 정의
  - `activity_model.dart`: 활동 데이터 모델
  - `todo_model.dart`: 할일 데이터 모델

- **Views**: UI 및 사용자 인터랙션 처리
  - `timer_screen.dart`: 메인 타이머 화면
  - `records_screen.dart`: 활동 기록 화면
  - `activity_input_dialog.dart`: 활동 입력 다이얼로그
  - `ios_audio_activation_screen.dart`: iOS 오디오 활성화 화면

- **ViewModels**: 비즈니스 로직과 데이터 처리
  - `alarm_viewmodel.dart`: 알람 및 타이머 로직
  - `records_viewmodel.dart`: 활동 기록 관리
  - `todo_viewmodel.dart`: 할일 관리

- **Services**: 데이터 저장 및 알림 처리
  - `storage_service.dart`: 로컬 스토리지 관리
  - `notification_service.dart`: 알림 처리
  - `todo_service.dart`: 할일 데이터 관리

### 주요 파일 구조
```
lib/
├── main.dart                    # 앱 진입점
├── platform_helper.dart         # 플랫폼 감지 유틸리티
├── models/
│   ├── activity_model.dart      # 활동 데이터 모델
│   └── todo_model.dart          # 할일 데이터 모델
├── services/
│   ├── notification_service.dart # 알림 서비스
│   ├── storage_service.dart     # 로컬 스토리지 서비스
│   └── todo_service.dart        # 할일 관리 서비스
├── utils/
│   └── date_formatter.dart      # 날짜 포맷 유틸리티
├── viewmodels/
│   ├── alarm_viewmodel.dart     # 알람 뷰모델
│   ├── records_viewmodel.dart   # 기록 뷰모델
│   └── todo_viewmodel.dart      # 할일 뷰모델
└── views/
    ├── activity_input_dialog.dart # 활동 입력 다이얼로그
    ├── ios_audio_activation_screen.dart # iOS 오디오 활성화 화면
    ├── records_screen.dart      # 기록 화면
    └── timer_screen.dart        # 타이머 화면
```

## 앱 사용법

### 타이머 설정 및 사용
1. 앱을 처음 시작하면 알람 간격(분)을 설정하라는 메시지가 표시됩니다.
2. 타이머가 시작되고 상단의 프로그레스 바와 함께 남은 시간이 표시됩니다.
3. 타이머 시간을 변경하려면 시간 표시를 탭하여 새로운 시간을 설정할 수 있습니다.
4. 타이머가 끝나면 알림이 표시되고 현재 활동을 기록하라는 메시지가 표시됩니다.

### 활동 기록
1. 언제든지 "활동 기록" 버튼을 눌러 수동으로 활동을 기록할 수 있습니다.
2. 활동 입력 다이얼로그에서 활동 내용, 카테고리, 시간, 날짜를 입력할 수 있습니다.
3. 기록된 활동은 "기록" 탭에서 확인할 수 있습니다.

### 할일 관리
1. 화면 하단의 입력 필드에 할일을 입력하고 추가할 수 있습니다.
2. 할일 목록에서 항목을 탭하여 완료 상태를 토글할 수 있습니다.
3. 할일 항목을 왼쪽으로 스와이프하여 삭제할 수 있습니다.
4. 기록 화면의 할일 탭에서 날짜별 할일을 확인할 수 있습니다.

### 기록 화면
1. 기록 화면에서는 활동 기록과 할일 목록을 탭으로 전환하여 볼 수 있습니다.
2. 활동 탭에서는 히트맵과 날짜별 활동 목록을 확인할 수 있습니다.
3. 할일 탭에서는 날짜별 할일 목록을 확인할 수 있습니다.

## 브라우저 호환성 및 제한사항

### 지원 브라우저
- Chrome (데스크톱 및 모바일)
- Safari (iOS)
- Firefox
- Edge

### iOS Safari 제한사항
iOS Safari에는 다음과 같은 제한사항이 있습니다:
- 웹 푸시 알림(Web Push API)이 지원되지 않음
- 백그라운드에서 오디오 재생이 제한적
- 화면이 꺼진 상태에서 타이머 작동이 제한적

이러한 제한을 극복하기 위해 다음과 같은 기술을 사용했습니다:
- Web Audio API를 사용한 무음 오디오 생성
- Wake Lock API를 통한 화면 켜짐 유지
- 로컬 스토리지 기반 타이머 상태 추적
- 다중 알림 전략(오디오+진동+알림)

## 기여 방법

1. 이 저장소를 포크합니다.
2. 새 기능 브랜치를 생성합니다: `git checkout -b feature/amazing-feature`
3. 변경 사항을 커밋합니다: `git commit -m 'Add some amazing feature'`
4. 브랜치에 푸시합니다: `git push origin feature/amazing-feature`
5. Pull Request를 제출합니다.

## 문제 해결

### 알람이 울리지 않는 경우
- iOS Safari에서는 사용자 상호작용(화면 탭)이 필요할 수 있습니다.
- 브라우저 설정에서 소리 재생이 허용되어 있는지 확인하세요.
- 기기가 진동을 지원하는지 확인하세요.

### 타이머가 백그라운드에서 작동하지 않는 경우
- 배터리 최적화 설정을 확인하세요.
- PWA로 설치하여 사용해 보세요.
- 브라우저를 최신 버전으로 업데이트하세요.

### 기타 문제
- 브라우저 캐시를 지우고 다시 시도해 보세요.
- 문제가 지속되면 이슈를 제출해 주세요.

## 라이선스

MIT 라이선스

## 연락처

GitHub: [woodyalmond](https://github.com/woodyalmond)
