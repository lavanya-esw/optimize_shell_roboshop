#!/bin/bash

#colour codes
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[37m"
B="\e[34m"

SCRIPT_DIR=$PWD
START_TIME=$(date +%s)
LOG_DIR=/var/log/shell_roboshop_project
SCRIPT_NAME=$( echo $0 | cut -d "." -f1 )
LOG_FILE=${LOG_DIR}/${SCRIPT_NAME}.log
mkdir -p $LOG_DIR

#To check root user or not
CHECK_ROOT()
{
    ROOT_USER=$(id -u)
    if [ $ROOT_USER -ne 0 ]; then
        echo "Pease run the script under root privilages"
        exit 1
    fi
}

VALIDATE()
{
    if [ $1 -ne 0 ]; then
        echo -e "$2...$R FAILURE $N"
    else
        echo -e "$2...$G SUCCESS $N"
    fi
}

NODE_JS_SETUP()
{
    dnf module disable nodejs -y &>>$LOG_FILE
    VALIDATE $? "disable nodejs"
    dnf module enable nodejs:20 -y &>>$LOG_FILE
    VALIDATE $? "enable nodejs"
    dnf install nodejs -y &>>$LOG_FILE
    VALIDATE $? "install nodejs"

    npm install &>>$LOG_FILE
    VALIDATE $? "Install dependencies"
}

JAVA_SETUP()
{
    dnf install maven -y &>>$LOG_FILE
    VALIDATE $? "installing maven"
    mvn clean package &>>$LOG_FILE
    VALIDATE $? "Packing the application"
    mv target/shipping-1.0.jar shipping.jar &>>$LOG_FILE
    VALIDATE $? "Renaming the artifact"
}

PYTHON_SETUP()
{
    dnf install python3 gcc python3-devel -y &>>$LOG_FILE
    VALIDATE $? "Installing Python3"
    pip3 install -r requirements.txt &>>$LOG_FILE
    VALIDATE $? "Installing dependencies"
}


APP_SETUP()
{
    id roboshop
    if [ $? -ne 0 ]; then
        echo "creating roboshop user"
        useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
        VALIDATE $? "Creating system user"
    else
        echo -e "roboshop user is already created.....$Y SKIPPING $N"
    fi    

    mkdir -p /app 
    VALIDATE $? "create app folder"

    curl -o /tmp/$APP_NAME.zip https://roboshop-artifacts.s3.amazonaws.com/$APP_NAME-v3.zip &>>$LOG_FILE
    VALIDATE $? "Downloading $APP_NAME application"

    cd /app 
    VALIDATE $? "Changing to app directory"

    rm -rf /app/*
    VALIDATE $? "Removing existing code"

    unzip /tmp/$APP_NAME.zip &>>$LOG_FILE
    VALIDATE $? "unzip $APP_NAME"
}


SYSTEM_SETUP()
{

    cp $SCRIPT_DIR/$APP_NAME.service /etc/systemd/system/$APP_NAME.service
    VALIDATE $? "Copy systemctl service"
    systemctl daemon-reload
    systemctl enable $APP_NAME &>>$LOG_FILE
    VALIDATE $? "Enable $APP_NAME"
}

APP_RESTART()
{
    systemctl restart $APP_NAME
    VALIDATE $? "Restarted $APP_NAME"
}

PRINT_TOTAL_TIME(){
    END_TIME=$(date +%s)
    TOTAL_TIME=$(( $END_TIME - $START_TIME ))
    echo -e "Script executed in: $Y $TOTAL_TIME Seconds $N"
}