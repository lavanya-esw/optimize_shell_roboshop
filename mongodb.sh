#!/bin/bash

source ./common.sh

CHECK_ROOT

cp $SCRIPT_DIR/mongo.repo /etc/yum.repos.d/mongo.repo
VALIDATE $? "Adding mongo repo"

dnf list installed | grep mongodb &>>$LOG_FILE
if [ $? -ne 0 ]; then
    dnf install mongodb-org -y &>>$LOG_FILE
    VALIDATE $? "install mongodb"
else
    echo -e "Mongodb already installed....$Y SKIPPING $N"
fi

systemctl enable mongod &>>$LOG_FILE
VALIDATE $? "enabling mongodb"

systemctl start mongod 
VALIDATE $? "starting mongodb"

sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf
VALIDATE $? "Allowing remote connections to MongoDB"

systemctl restart mongod
VALIDATE $? "start mongodb"

PRINT_TOTAL_TIME
