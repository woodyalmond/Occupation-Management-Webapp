# alarmapp AWS 3-Tier 배포 가이드

수업 인프라(Web Nginx -> WAS -> RDS MySQL)에 alarmapp(지금뭐해)을 올리는 절차입니다.

Tomcat JDBC 게시판과의 차이: WAS는 **Python API**(`api/server.py`), DB 연결은 **`.env`의 MYSQL_*** 입니다.

## 아키텍처

```text
브라우저
  -> Web EC2 (Nginx :80)
       /          -> Flutter Web 정적 (index.html, main.dart.js)
       /api/*     -> WAS EC2 Python API (:8000)
  -> RDS MySQL (alarmapp DB)
```

Docker Compose 로컬과 동일한 역할 분리입니다. WAS만 Tomcat 대신 Python입니다.

## Tier 1. RDS MySQL

### 1) DB 생성

Workbench(Bastion SSH)에서 `db/init/001_create_tasks.sql` 실행.

또는 RDS 생성 시 **초기 데이터베이스 이름**을 `alarmapp`으로 지정한 뒤, 같은 파일에서 `CREATE DATABASE` 줄은 생략하고 `USE alarmapp;` 이후만 실행합니다.

### 2) 수업 RDS와 공존

| DB | 용도 |
|---|---|
| `board_db` | 수업 게시판 (Tomcat JDBC) |
| `alarmapp` | alarmapp 할일/활동 |

같은 RDS 인스턴스, DB 이름만 분리합니다.

### 3) 보안 그룹

RDS SG 인바운드 3306:

- Web EC2 SG (불필요, API만 DB 접속)
- **WAS EC2 SG** (Python API가 RDS 접속)
- Bastion SG (Workbench SSH 터널용, 선택)

수업처럼 `0.0.0.0/0`은 편하지만 운영에서는 WAS SG만 허용하세요.

## Tier 2. WAS (Python API)

WAS EC2(Ubuntu 24.04 등)에서:

```bash
sudo apt-get update
sudo apt-get install -y python3 python3-pip python3-venv git

cd /opt/alarmapp/api
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

`.env` 작성 (`.env.example` 참고):

```env
MYSQL_HOST=<RDS 엔드포인트>
MYSQL_PORT=3306
MYSQL_DATABASE=alarmapp
MYSQL_USER=admin
MYSQL_PASSWORD=<RDS 마스터 암호>
API_HOST=0.0.0.0
API_PORT=8000
```

API 실행:

```bash
cd /opt/alarmapp/api
source .venv/bin/activate
set -a && source .env && set +a
python server.py
```

헬스 체크:

```bash
curl http://127.0.0.1:8000/health
```

systemd 등으로 상시 실행하는 것을 권장합니다.

## Tier 3. Web (Nginx + Flutter Web)

### 1) Flutter Web 빌드

빌드 머신(Flutter SDK 설치된 PC 또는 EC2):

```bash
cd projects/alarmapp/app
flutter pub get
flutter build web --release --pwa-strategy=none --dart-define=API_BASE_URL=
```

`API_BASE_URL`을 **비워 두면** 브라우저가 같은 도메인의 `/api/*`를 호출합니다(Nginx 프록시와 짝).

### 2) 정적 파일 배치

```bash
sudo mkdir -p /var/www/alarmapp
sudo rsync -a build/web/ /var/www/alarmapp/
```

### 3) Nginx 설정

`deploy/nginx.alarmapp.conf.example`를 참고해 Web EC2에 적용합니다.

WAS가 **다른 EC2**이면 `proxy_pass`를 WAS private IP로 변경:

```nginx
proxy_pass http://10.0.x.x:8000/api/;
```

Web/WAS가 **같은 EC2**이면 `127.0.0.1:8000` 사용.

```bash
sudo nginx -t
sudo systemctl reload nginx
```

## Docker Compose (EC2 한 대에서 전부)

RDS를 쓰는 경우 `docker-compose.yml`의 `mariadb` 서비스는 끄고, `api`에 RDS env만 넘깁니다.

```yaml
api:
  environment:
    MYSQL_HOST: your-rds-endpoint.ap-northeast-2.rds.amazonaws.com
    MYSQL_USER: admin
    MYSQL_PASSWORD: ${MYSQL_PASSWORD}
    MYSQL_DATABASE: alarmapp
```

`web` 서비스는 그대로 Nginx 8080 -> `/api/` -> api:8000.

## Tomcat JDBC 수업과 대응표

| 수업 (게시판) | alarmapp |
|---|---|
| Tomcat `server.xml` JNDI | Python `.env` MYSQL_* |
| `jdbc/MyDB` | PyMySQL 직접 연결 |
| `board_db.posts` | `alarmapp.tasks`, `activities` |
| MySQL Connector J JAR | `pip install pymysql` |
| WAR in Tomcat | `python server.py` (포트 8000) |

## 확인 체크리스트

- [ ] RDS `alarmapp` DB + 테이블 생성
- [ ] WAS에서 `curl http://127.0.0.1:8000/health` OK
- [ ] WAS에서 RDS 연결 (할일 POST/GET)
- [ ] Web Nginx `/` 정적 로드
- [ ] Web Nginx `/api/tasks` 프록시 OK
- [ ] 브라우저에서 할일 추가 후 RDS `tasks` 테이블에 row 확인

## 자주 막히는 지점

1. **Flutter가 127.0.0.1:8000 호출** -> 빌드 시 `--dart-define=API_BASE_URL=` 필수
2. **RDS SG에 WAS EC2 미등록** -> API는 뜨지만 DB connection refused
3. **퍼블릭 RDS + 0.0.0.0/0** -> 수업용만, 운영은 private subnet + SG 제한
