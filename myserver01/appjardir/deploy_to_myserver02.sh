#!/bin/bash

# 변수 설정
LOCAL_JAR_PATH="/home/username/appjardir/SpringApp-0.0.1-SNAPSHOT.jar"
REMOTE_SERVER="username@10.0.2.19"
REMOTE_DIR="/home/username/my2cicd"
REMOTE_JAR_PATH="$REMOTE_DIR/SpringApp-0.0.1-SNAPSHOT.jar"
REMOTE_PORT=8999

# 파일 전송 (scp)
echo "Deploying JAR file to myserver02..."
scp $LOCAL_JAR_PATH $REMOTE_SERVER:$REMOTE_DIR

# 원격 서버에서 애플리케이션 실행
echo "Executing JAR file on myserver02..."
ssh $REMOTE_SERVER << EOF
    # 기존 애플리케이션 종료 (포트 8999에서 실행 중인 프로세스 종료)
    PID=\$(lsof -t -i :$REMOTE_PORT)
    if [ -n "\$PID" ]; then
        echo "Stopping existing application (PID: \$PID)..."
        kill -9 \$PID
    else
        echo "No application is currently running on port $REMOTE_PORT."
    fi

    # 새로운 JAR 파일 실행
    echo "Starting new application..."
    nohup java -jar $REMOTE_JAR_PATH > $REMOTE_DIR/app.log 2>&1 &
    echo "Application started successfully."
EOF

echo "Deployment completed!"
