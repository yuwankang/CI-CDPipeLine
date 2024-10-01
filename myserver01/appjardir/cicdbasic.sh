#!/bin/bash

# 변수 설정
JAR_FILE="SpringApp-0.0.1-SNAPSHOT.jar"
DEPLOY_DIR="/home/username/step07cicd"
BACKUP_FILE="$DEPLOY_DIR/SpringApp-0.0.1-SNAPSHOT.jar.bak"
LOG_FILE="$DEPLOY_DIR/app.log"

# 이전 JAR 파일 백업
if [ -f "$DEPLOY_DIR/SpringApp-0.0.1-SNAPSHOT.jar" ]; then
  echo "이전 JAR 파일을 백업합니다: $BACKUP_FILE"
  mv "$DEPLOY_DIR/SpringApp-0.0.1-SNAPSHOT.jar" "$BACKUP_FILE"
fi

# 새로운 JAR 파일 복사
if [ -f "$JAR_FILE" ]; then
  echo "새로운 JAR 파일을 복사합니다: $JAR_FILE -> $DEPLOY_DIR/"
  cp "$JAR_FILE" "$DEPLOY_DIR/"
else
  echo "JAR 파일을 찾을 수 없습니다: $JAR_FILE"
  exit 1
fi

# 기존 8999 포트 사용 중인 프로세스 종료
if sudo lsof -i :8999 > /dev/null; then
  echo "8999 포트를 사용하는 프로세스를 종료합니다."
  sudo kill -9 $(sudo lsof -t -i:8999)
fi

# 백그라운드에서 새로 실행
echo "Spring Boot 애플리케이션을 백그라운드에서 실행합니다."
nohup java -jar "$DEPLOY_DIR/SpringApp-0.0.1-SNAPSHOT.jar" > "$LOG_FILE" 2>&1 &

echo "배포 완료 및 애플리케이션이 실행 중입니다. 로그는 $LOG_FILE에서 확인할 수 있습니다."