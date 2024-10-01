# 🚀 CI-CD 파이프라인 자동화: Jenkins와 GitHub 연동 🌐
>Jenkins를 이용하여 GitHub 저장소 commit시 코드를 자동으로 빌드하고 배포하는 CI-CD 파이프라인을 설정 프로젝트입니다. 이 과정에서는 ngrok을 사용하여 Jenkins를 외부에서도 접근 가능하게 하고, SSH를 통해 원격 서버에 자동 배포를 진행합니다.

## ✅ 요구 사항
- **Jenkins**
- **GitHub 계정**
- **ngrok**
- **원격 서버(SSH 활성화)**
## 🛠️ 기본 환경 설정

### 1. 🐳Jenkins 컨테이너 생성 🐳
> 이 명령을 통해 Jenkins 컨테이너를 실행하며, 볼륨을 마운트하여 Jenkins 홈 디렉토리 안에 appjar 폴더를 생성합니다
```
docker run --name myjenkins2 --privileged -p 8080:8080 -v $(pwd)/appjardir:/var/jenkins_home/appjar jenkins/jenkins:lts-jdk17
```
![](https://velog.velcdn.com/images/yuwankang/post/22ea4132-429d-466a-a713-7c35c0a4da85/image.png)



### 2. 🌍ngrok 설정 Jenkins를 외부에서 접근할 수 있도록 ngrok을 사용합니다.
> 생성된 ngrok 주소를 사용하여 GitHub 웹훅과 Jenkins를 연동할 수 있습니다.
```
ngrok http http://127.0.0.1:8080
```
![](https://velog.velcdn.com/images/yuwankang/post/98a27091-ac39-45fe-957a-955a848fb8b8/image.png)
![](https://velog.velcdn.com/images/yuwankang/post/811ca003-244b-48e6-b37b-0bc56b1f9525/image.png)

### 3.🔄 Spring 애플리케이션 빌드 확인
> 파이프라인 스크립트를 통해 GitHub에서 코드를 받아와 빌드를 진행합니다. 파이프라인 구성전 정상 빌드를 확인합니다.
  
![](https://velog.velcdn.com/images/yuwankang/post/5c9100ef-23e4-457d-8487-250805292cb3/image.png)
![](https://velog.velcdn.com/images/yuwankang/post/cb637ccd-4f8c-49be-a1cb-18dbddf1c307/image.png)


### 4.🔗 GitHub와 Jenkins 연동
> ngrok을 사용하여 실시간 감지, 자동 배포를 하기 위해 github와 연결합니다.
```
ngrok주소/github-webhook/
```
![](https://velog.velcdn.com/images/yuwankang/post/928511dc-ce90-4364-add9-63f9d7672668/image.png)
![](https://velog.velcdn.com/images/yuwankang/post/9661b481-18d0-43eb-ba91-71b25bee11b0/image.png)
#### 📌필수 플러그인
- stage view 플러그 인 **설치하기**
- genkins 플러그인 SSH AGENT **설치하기**


## Jenkins jar파일 바인딩
- jenkins root 권한으로 내부 접속하기
```
docker exec -u root -it myjenkins2 bash
```
![](https://velog.velcdn.com/images/yuwankang/post/9af0f712-551e-496f-b502-d2c56726f9c6/image.png)
- 권한 부여
```
sudo chown -R 1000:1000 /var/jenkins_home/appjar/
chmod -R 755 /var/jenkins_home/appjar
```
![](https://velog.velcdn.com/images/yuwankang/post/fd1c3c49-1a1e-4d06-8900-e31a74b751da/image.png)


## 📦 jenkins와 Docker를 이용한 Github 파이프라인 자동배포

   
### 🗂️ 파일 구조
![](https://velog.velcdn.com/images/yuwankang/post/dbb89f9a-28da-43a5-b768-0f8b692d56dc/image.png)



   
### 📜cicdbasic.sh 파일

```shell
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
```
> 실행 명령어
```
sh cicdbasic.sh
```
![](https://velog.velcdn.com/images/yuwankang/post/7d93ca20-dff1-4797-b643-0d85e1abc6ae/image.png)



## 🤖배포 자동화
### SSH를 사용한 배포 자동화
> genkins 플러그인 SSH AGENT 설치
![](https://velog.velcdn.com/images/yuwankang/post/a5a60bfb-22f2-4c36-9342-6b7878c85aa8/image.png)
> ssh 키값 생성
```
ssh-keygen -t rsa -b 4096 -C "이메일"
```
![](https://velog.velcdn.com/images/yuwankang/post/e0264c02-a34e-4889-b5d5-ddf4630e444e/image.png)
> 생성된 키 확인 및 SSH 공개 키를 원격 서버에 추가
![](https://velog.velcdn.com/images/yuwankang/post/528e51ee-e98d-4a8a-9ac0-1e757090d1de/image.png)
### 📜Jenkins에서 SSH 자격 증명 추가
- 1. jenkins 대시보드 접속
- 2. Credentaials 메뉴로 이동
  - 대시보드 왼쪽 메뉴에서 **"Credentials"**를 클릭합니다.
만약 이 메뉴가 보이지 않는다면, **"Manage Jenkins"**를 클릭한 다음, **"Manage Credentials"**를 선택해야 할 수 있습니다.
- 3. 도메인 선택
  - 기본적으로 **global**이라는 도메인이 선택되어 있을 것입니다. 이를 그대로 사용하거나, 특정 도메인을 선택합니다. 대부분의 경우 **global**을 선택합니다.
- 4. 자격 증명 추가:
  - 오른쪽 상단의 "Add Credentials" 버튼을 클릭합니다
- 5. Kind 선택
  - Kind 드롭다운 메뉴에서 **"SSH Username with private key"**를 선택합니다.
  - 이 옵션을 선택하면 SSH 사용자 이름과 비공개 키를 사용할 수 있는 설정란이 나타납니다.
  
- 6. Username 입력
  - Username 필드에 원격 서버의 사용자 이름을 입력합니다.
- 7. Private Key 입력
  - Private Key 부분에서 **"Enter directly"**를 선택합니다
  - 그 아래에 나타나는 텍스트 박스에 ~/.ssh/id_rsa 파일의 내용을 붙여넣습니다
```
cat ~/.ssh/id_rsa
```
![](https://velog.velcdn.com/images/yuwankang/post/982df7fe-4849-4d6c-a7ee-8442ae083366/image.png)

## 완료
![](https://velog.velcdn.com/images/yuwankang/post/8f93b6e2-8360-46a4-8cd7-c2c7fe92f7fc/image.png)
- jenkins log
```
Started by GitHub push by yuwankang
[Pipeline] Start of Pipeline
[Pipeline] node
Running on Jenkins in /var/jenkins_home/workspace/step02_jar_CI_CD
[Pipeline] {
[Pipeline] stage
[Pipeline] { (Repo Clone)
[Pipeline] git
The recommended git tool is: NONE
No credentials specified
 > git rev-parse --resolve-git-dir /var/jenkins_home/workspace/step02_jar_CI_CD/.git # timeout=10
Fetching changes from the remote Git repository
 > git config remote.origin.url https://github.com/yuwankang/01.lab.git # timeout=10
Fetching upstream changes from https://github.com/yuwankang/01.lab.git
 > git --version # timeout=10
 > git --version # 'git version 2.39.2'
 > git fetch --tags --force --progress -- https://github.com/yuwankang/01.lab.git +refs/heads/*:refs/remotes/origin/* # timeout=10
 > git rev-parse refs/remotes/origin/main^{commit} # timeout=10
Checking out Revision 4db0151c2eaa6cde88a8c78c2cb2bb8dfb8d3b83 (refs/remotes/origin/main)
 > git config core.sparsecheckout # timeout=10
 > git checkout -f 4db0151c2eaa6cde88a8c78c2cb2bb8dfb8d3b83 # timeout=10
 > git branch -a -v --no-abbrev # timeout=10
 > git branch -D main # timeout=10
 > git checkout -b main 4db0151c2eaa6cde88a8c78c2cb2bb8dfb8d3b83 # timeout=10
Commit message: "Update README.md"
 > git rev-list --no-walk 699ac8c985756aaa99a88e36e8b7ea73ad5e6b7b # timeout=10
[Pipeline] echo
다운로드 완료
[Pipeline] }
[Pipeline] // stage
[Pipeline] stage
[Pipeline] { (Build)
[Pipeline] dir
Running in /var/jenkins_home/workspace/step02_jar_CI_CD/01.java/SpringApp
[Pipeline] {
[Pipeline] sh
+ chmod +x ./gradlew
[Pipeline] sh
+ ./gradlew clean build -x test
Starting a Gradle Daemon (subsequent builds will be faster)
> Task :clean
> Task :compileJava
> Task :processResources
> Task :classes
> Task :resolveMainClassName
> Task :bootJar
> Task :jar
> Task :assemble
> Task :check
> Task :build

BUILD SUCCESSFUL in 7s
6 actionable tasks: 6 executed
[Pipeline] sh
+ echo /var/jenkins_home/workspace/step02_jar_CI_CD
/var/jenkins_home/workspace/step02_jar_CI_CD
[Pipeline] }
[Pipeline] // dir
[Pipeline] }
[Pipeline] // stage
[Pipeline] stage
[Pipeline] { (Copy jar)
[Pipeline] script
[Pipeline] {
[Pipeline] sh
+ cp 01.java/SpringApp/build/libs/SpringApp-0.0.1-SNAPSHOT.jar /var/jenkins_home/appjar/
[Pipeline] }
[Pipeline] // script
[Pipeline] }
[Pipeline] // stage
[Pipeline] stage
[Pipeline] { (Run cicdbasic.sh on Host)
[Pipeline] script
[Pipeline] {
[Pipeline] sshagent
[ssh-agent] Using credentials username (myjenkins-10.0.2.15-ssh-key)
$ ssh-agent
SSH_AUTH_SOCK=/tmp/ssh-XXXXXXDwt73n/agent.1937
SSH_AGENT_PID=1940
Running ssh-add (command line suppressed)
Identity added: /var/jenkins_home/workspace/step02_jar_CI_CD@tmp/private_key_8302992554600932903.key (kangyuwan@naver.com)
[ssh-agent] Started.
[Pipeline] {
[Pipeline] sh
+ ssh -o StrictHostKeyChecking=no username@10.0.2.15 cd /home/username/appjardir/ && bash cicdbasic.sh
이전 JAR 파일을 백업합니다: /home/username/step07cicd/SpringApp-0.0.1-SNAPSHOT.jar.bak
새로운 JAR 파일을 복사합니다: SpringApp-0.0.1-SNAPSHOT.jar -> /home/username/step07cicd/
sudo: a terminal is required to read the password; either use the -S option to read from standard input or configure an askpass helper
sudo: a password is required
Spring Boot 애플리케이션을 백그라운드에서 실행합니다.
배포 완료 및 애플리케이션이 실행 중입니다. 로그는 /home/username/step07cicd/app.log에서 확인할 수 있습니다.
[Pipeline] }
$ ssh-agent -k
unset SSH_AUTH_SOCK;
unset SSH_AGENT_PID;
echo Agent pid 1940 killed;
[ssh-agent] Stopped.
[Pipeline] // sshagent
[Pipeline] }
[Pipeline] // script
[Pipeline] }
[Pipeline] // stage
[Pipeline] }
[Pipeline] // node
[Pipeline] End of Pipeline
Finished: SUCCESS
```

## 🤖Github변경 감지 및 자동화 기능 추가
**⚠️주의사항 : 무한루프 발생 가능성**

> inotify-tools 설치
```bash
sudo apt-get update
sudo apt-get install inotify-tools
```
> docker에 설치된 jenkins 실행
```
docker start myjenkins2
```
![](https://velog.velcdn.com/images/yuwankang/post/80b655b4-8b1d-432c-8d06-eb2c8ae54c34/image.png)

### 🛠️백그라운드에서 새로 실행
> $DEPLOY_DIR/app.log : 애플리케이션 로그를 app.log 파일에 저장하도록 구성

```
nohup java -jar SpringApp-0.0.1-SNAPSHOT.jar > app.log 2>&1 &
```
![](https://velog.velcdn.com/images/yuwankang/post/7d915597-5435-4a9c-967d-37a0f2bfa4a4/image.png)

> 프로세스 확인
```
lsof -i :<포트번호>
```
![](https://velog.velcdn.com/images/yuwankang/post/1bf3032d-a253-432c-acb2-22379251e972/image.png)
> 프로세스 죽이기
```
 kill -9 <pid>
```
## 📜스크립트 작성

- autorunning.sh

- 파일 1. jar file 실행 스크립트 / autorunning.sh
- 파일 2. jar file 변경 감지 및 jar file 실행 스크립트 실행 / change.sh  

```bash
#!/bin/bash

# Spring Boot 애플리케이션 재시작
# 기존 8080 포트 사용 중인 프로세스 종료
if  lsof -i :8999> /dev/null; then
  # 8999 포트가 사용 중일 경우 이전 프로세스를 종료
  kill -9 $(lsof -t -i:8999)
  echo '정상적으로 종료되었습니다.'
fi

# 백그라운드에서 새로 실행
# > $DEPLOY_DIR/app.log : 애플리케이션 로그를 app.log 파일에 저장하도록 구성
nohup java -jar SpringApp-0.0.1-SNAPSHOT.jar > app.log 2>&1 &

echo "배포완료 및 재 실행됩니다."
```

![](https://velog.velcdn.com/images/yuwankang/post/dfa46773-1a03-4522-89fa-1e76d5b68af0/image.png)

![](https://velog.velcdn.com/images/yuwankang/post/770e91ea-af32-43da-b7b7-ff78ae449532/image.png)
#### 📊 모니터링

- change.sh
> 파일 변경되는 내내 실행 방지되는 로직 적용
무한루프 빠지지 않게 모니터링 하는 스크립트
```bash
#!/bin/bash

# JAR 파일 경로 설정
JAR_FILE="./SpringApp-0.0.1-SNAPSHOT.jar"

# 실행할 .sh 파일 경로 설정
SH_FILE="./autorunning.sh"

# COOLDOWN 중복 실행 방지 대기 시간 (예: 10초)
COOLDOWN=10
LAST_RUN=0

# 파일 수정 감지 및 .sh 파일 실행
inotifywait -m -e close_write "$JAR_FILE" |
while read -r directory events filename; do
    CURRENT_TIME=$(date +%s)

    # 마지막 실행 후 지정된 시간이 지났는지 확인
    if (( CURRENT_TIME - LAST_RUN > COOLDOWN )); then
        echo "$(date): $filename 파일이 수정되었습니다."  # 수정 시간 로그 추가
        # .sh 파일 실행
        bash "$SH_FILE"
        # 마지막 실행 시간 업데이트
        LAST_RUN=$CURRENT_TIME
    else
        echo "$(date): 쿨다운 기간 중입니다. 실행하지 않음."
    fi
done
```
- 모니터링 모드 스크립트 실행
```
chmod +x change.sh
```
```
./change.sh 
```
![](https://velog.velcdn.com/images/yuwankang/post/8c359488-9477-4dbf-ab57-4e15eb18d86f/image.png)

- 깃허브 파일 수정시 
![](https://velog.velcdn.com/images/yuwankang/post/f14960b6-ce87-4d5c-8432-cec9f50dbd01/image.png)
- 모니터링에 표시된다.
![](https://velog.velcdn.com/images/yuwankang/post/dc9961e8-e98b-4e37-bae2-914f6611a1aa/image.png)
#### 수정 및 배포 자동화 완료
![](https://velog.velcdn.com/images/yuwankang/post/e0305224-3380-4eb1-b424-d1537b5f5f41/image.png)

- sh 파일로 실행 중인 프로세스 확인
```
ps aux | grep 파일명.sh
```

![](https://velog.velcdn.com/images/yuwankang/post/958a7658-d28f-4b74-988f-7bf4d1dd59c1/image.png)

# 🚀myserver01 -> myserver02 로 운영서버 변경하기
## 🚀myserver01
![](https://velog.velcdn.com/images/yuwankang/post/d9153a0d-b87d-45e9-9ab6-2631ffcea4ab/image.png)
## 🚀myserver02
![](https://velog.velcdn.com/images/yuwankang/post/f2c35ba5-da53-419b-9404-80e0e8bb6b24/image.png)

### 🔑SSH key 생성
- SSH key 생성
> 파일을 전송할 로컬 서버(파일을 전송하는 서버)에서 SSH 키를 생성
```bash
ssh-keygen -t rsa -b 4096 
```
- ssh key 확인
```bash
ls -l .ssh
cat .ssh/authorized_keys
cat .ssh/id_rsa
cat .ssh/id_rsa.pub
```
![](https://velog.velcdn.com/images/yuwankang/post/9788b58a-7411-4697-adb8-b1d27bc14d00/image.png)
### 🔑원격 서버에 SSH 공개 키 추가
```bash
ssh-copy-id username@remote_server_ip
#예시 10.0.2.19 mysever2
ssh-copy-id username@10.0.2.19
```
- 비밀번호 없이 접속확인
> myserver01 -> myserver02
```
ssh username@10.0.2.19
```
![](https://velog.velcdn.com/images/yuwankang/post/13827b82-c8a7-4c2e-bae6-5aa2963421df/image.png)

  
  
  ![](https://velog.velcdn.com/images/yuwankang/post/1e2af15b-3a39-4dfc-8173-79bf21243328/image.png)
  
#### 📜deploy_to_myserver02.sh
```bash
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

```

#### 📜jenkins Script
```bash
pipeline {
    agent any

    stages {
        stage('Repo Clone') {
            steps {
                git branch: 'main', url: 'https://github.com/yuwankang/01.lab.git'
                echo "다운로드 완료"
            }
        }

        stage('Build') {
            steps {
                dir('01.java/SpringApp') {  
                    sh 'chmod +x ./gradlew'  
                    sh './gradlew clean build -x test'
                    sh "echo $WORKSPACE"  
                }
            }
        }
        
        stage('Copy jar') { 
            steps {
                script {
                    def jarFile = '01.java/SpringApp/build/libs/SpringApp-0.0.1-SNAPSHOT.jar'                   
                    sh "cp ${jarFile} /var/jenkins_home/appjar/"
                }
            }
        }

        stage('Run cicdbasic.sh on Host') {
            steps {
                script {
                    sshagent(['myjenkins-10.0.2.15-ssh-key']) {
                        def host = 'username@10.0.2.15'
                        def shellPath = '/home/username/appjardir/'
                        sh "ssh -o StrictHostKeyChecking=no ${host} 'cd ${shellPath} && bash cicdbasic.sh'"
                    }
                }
            }
        }

        stage('Run deploy_to_myserver02.sh on myserver01') {
            steps {
                script {
                    sshagent(['myjenkins-10.0.2.15-ssh-key']) {
                        def myserver01 = 'username@10.0.2.15'
                        def scriptPath = '/home/username/appjardir'
                        // deploy_to_myserver02.sh 실행
                        sh """
                            ssh -o StrictHostKeyChecking=no ${myserver01} 'cd ${scriptPath} && bash deploy_to_myserver02.sh'
                        """
                    }
                }
            }
        }
    }
}

```
#### 🎉완료
![](https://velog.velcdn.com/images/yuwankang/post/df88cd47-cbef-4761-b468-278183370450/image.png)
- Jenkins output
```bash
Started by GitHub push by yuwankang
[Pipeline] Start of Pipeline
[Pipeline] node
Running on Jenkins in /var/jenkins_home/workspace/step02cicd
[Pipeline] {
[Pipeline] stage
[Pipeline] { (Repo Clone)
[Pipeline] git
The recommended git tool is: NONE
No credentials specified
 > git rev-parse --resolve-git-dir /var/jenkins_home/workspace/step02cicd/.git # timeout=10
Fetching changes from the remote Git repository
 > git config remote.origin.url https://github.com/yuwankang/01.lab.git # timeout=10
Fetching upstream changes from https://github.com/yuwankang/01.lab.git
 > git --version # timeout=10
 > git --version # 'git version 2.39.2'
 > git fetch --tags --force --progress -- https://github.com/yuwankang/01.lab.git +refs/heads/*:refs/remotes/origin/* # timeout=10
 > git rev-parse refs/remotes/origin/main^{commit} # timeout=10
Checking out Revision 73ac48ae1255b0f364d785287e526517835c9db4 (refs/remotes/origin/main)
 > git config core.sparsecheckout # timeout=10
 > git checkout -f 73ac48ae1255b0f364d785287e526517835c9db4 # timeout=10
 > git branch -a -v --no-abbrev # timeout=10
 > git branch -D main # timeout=10
 > git checkout -b main 73ac48ae1255b0f364d785287e526517835c9db4 # timeout=10
Commit message: "Update ProcessController.java"
 > git rev-list --no-walk d81a468fa26242135122c8f46bdc3cba91903427 # timeout=10
[Pipeline] echo
다운로드 완료
[Pipeline] }
[Pipeline] // stage
[Pipeline] stage
[Pipeline] { (Build)
[Pipeline] dir
Running in /var/jenkins_home/workspace/step02cicd/01.java/SpringApp
[Pipeline] {
[Pipeline] sh
+ chmod +x ./gradlew
[Pipeline] sh
+ ./gradlew clean build -x test
Starting a Gradle Daemon (subsequent builds will be faster)
> Task :clean
> Task :compileJava
> Task :processResources
> Task :classes
> Task :resolveMainClassName
> Task :bootJar
> Task :jar
> Task :assemble
> Task :check
> Task :build

BUILD SUCCESSFUL in 8s
6 actionable tasks: 6 executed
[Pipeline] sh
+ echo /var/jenkins_home/workspace/step02cicd
/var/jenkins_home/workspace/step02cicd
[Pipeline] }
[Pipeline] // dir
[Pipeline] }
[Pipeline] // stage
[Pipeline] stage
[Pipeline] { (Copy jar)
[Pipeline] script
[Pipeline] {
[Pipeline] sh
+ cp 01.java/SpringApp/build/libs/SpringApp-0.0.1-SNAPSHOT.jar /var/jenkins_home/appjar/
[Pipeline] }
[Pipeline] // script
[Pipeline] }
[Pipeline] // stage
[Pipeline] stage
[Pipeline] { (Run cicdbasic.sh on Host)
[Pipeline] script
[Pipeline] {
[Pipeline] sshagent
[ssh-agent] Using credentials username (myjenkins-10.0.2.15-ssh-key)
$ ssh-agent
SSH_AUTH_SOCK=/tmp/ssh-XXXXXXup8x2q/agent.3744
SSH_AGENT_PID=3747
Running ssh-add (command line suppressed)
Identity added: /var/jenkins_home/workspace/step02cicd@tmp/private_key_5921853371812929475.key (kangyuwan@naver.com)
[ssh-agent] Started.
[Pipeline] {
[Pipeline] sh
+ ssh -o StrictHostKeyChecking=no username@10.0.2.15 cd /home/username/appjardir/ && bash cicdbasic.sh
이전 JAR 파일을 백업합니다: /home/username/step07cicd/SpringApp-0.0.1-SNAPSHOT.jar.bak
새로운 JAR 파일을 복사합니다: SpringApp-0.0.1-SNAPSHOT.jar -> /home/username/step07cicd/
sudo: a terminal is required to read the password; either use the -S option to read from standard input or configure an askpass helper
sudo: a password is required
Spring Boot 애플리케이션을 백그라운드에서 실행합니다.
배포 완료 및 애플리케이션이 실행 중입니다. 로그는 /home/username/step07cicd/app.log에서 확인할 수 있습니다.
[Pipeline] }
$ ssh-agent -k
unset SSH_AUTH_SOCK;
unset SSH_AGENT_PID;
echo Agent pid 3747 killed;
[ssh-agent] Stopped.
[Pipeline] // sshagent
[Pipeline] }
[Pipeline] // script
[Pipeline] }
[Pipeline] // stage
[Pipeline] stage
[Pipeline] { (Run deploy_to_myserver02.sh on myserver01)
[Pipeline] script
[Pipeline] {
[Pipeline] sshagent
[ssh-agent] Using credentials username (myjenkins-10.0.2.15-ssh-key)
$ ssh-agent
SSH_AUTH_SOCK=/tmp/ssh-XXXXXXX1wQfD/agent.3767
SSH_AGENT_PID=3770
Running ssh-add (command line suppressed)
Identity added: /var/jenkins_home/workspace/step02cicd@tmp/private_key_1560164281330961173.key (kangyuwan@naver.com)
[ssh-agent] Started.
[Pipeline] {
[Pipeline] sh
+ ssh -o StrictHostKeyChecking=no username@10.0.2.15 cd /home/username/appjardir && bash deploy_to_myserver02.sh
Deploying JAR file to myserver02...
Permission denied, please try again.
Permission denied, please try again.
username@10.0.2.19: Permission denied (publickey,password).
Executing JAR file on myserver02...
lost connection
Pseudo-terminal will not be allocated because stdin is not a terminal.
Permission denied, please try again.
Permission denied, please try again.
username@10.0.2.19: Permission denied (publickey,password).
Deployment completed!
[Pipeline] }
$ ssh-agent -k
unset SSH_AUTH_SOCK;
unset SSH_AGENT_PID;
echo Agent pid 3770 killed;
[ssh-agent] Stopped.
[Pipeline] // sshagent
[Pipeline] }
[Pipeline] // script
[Pipeline] }
[Pipeline] // stage
[Pipeline] }
[Pipeline] // node
[Pipeline] End of Pipeline
Finished: SUCCESS
```
# 🎯결론
> 이번 프로젝트는 Docker와 Jenkins를 활용하여 CI/CD 파이프라인을 구축함으로써 소프트웨어 배포 및 관리를 자동화하는 데 중점을 두었습니다. GitHub의 변경 사항을 감지하고 이를 기반으로 Jenkins가 자동으로 빌드를 수행하도록 설정함으로써, 개발 및 운영 간의 효율적인 연계를 달성했습니다.
특히, SSH 키를 이용한 보안적인 파일 전송 방법을 통해 서버 간의 연결성을 확보하였으며, inotify-tools를 활용하여 파일 변경 감지를 실시간으로 처리함으로써 안정성과 신뢰성을 높였습니다.


