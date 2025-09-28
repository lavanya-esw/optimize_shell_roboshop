#!/bin/bash
APP_NAME="catalogue"
MONGODB_SERVER_IPADDRESS="mongodb.awsdevops.fun"

CHECK_ROOT


cp $SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service
VALIDATE $? "Copy systemctl service"

APP_SETUP

NODE_JS_SETUP

SYSTEM_SETUP


cp $SCRIPT_DIR/mongo.repo /etc/yum.repos.d/mongo.repo
VALIDATE $? "Copy mongo repo"

dnf install mongodb-mongosh -y &>>$LOG_FILE
VALIDATE $? "Install MongoDB client"


INDEX=$(mongosh $MONGODB_SERVER_IPADDRESS --quiet --eval "db.getMongo().getDBNames().indexOf('catalogue')")
if [ $INDEX -ne 0 ]; then
    mongosh --host $MONGODB_SERVER_IPADDRESS </app/db/master-data.js &>>$LOG_FILE
    VALIDATE $? "Load catalogue products"
else
    echo -e "Catalogue products already loaded ... $Y SKIPPING $N"
fi

APP_RESTART

PRINT_TOTAL_TIME


    



