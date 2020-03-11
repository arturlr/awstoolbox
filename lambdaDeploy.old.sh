#!/usr/bin/env bash

DARKGRAY='\033[1;30m'
RED='\033[0;31m'    
LIGHTRED='\033[1;31m'
GREEN='\033[0;32m'    
YELLOW='\033[1;33m'
BLUE='\033[0;34m'    
PURPLE='\033[0;35m'    
LIGHTPURPLE='\033[1;35m'
CYAN='\033[0;36m'    
WHITE='\033[1;37m'
SET='\033[0m'
DATESUFFIX=$(date +%Y-%m-%d-%H%M)

git_init () {
  echo -e "${YELLOW}Initializing Git${SET}"
  aws codecommit create-repository \
  --repository-name $LAMBDA_NAME \
  --repository-description "$LAMBDA_NAME Lambda Function" \
  --region $AWS_DEFAULT_REGION

  cd "${curdir}/$LAMBDA_NAME"
  git init
  git config --global user.email "no-reply@myemail.com"
  git config --global user.name "devuser"
  git remote add origin ssh://git-codecommit.$AWS_DEFAULT_REGION.amazonaws.com/v1/repos/$LAMBDA_NAME
  git add *
  git commit -m "Inital commit"
  git push origin master
}

git_sync () {
  echo -e "Commiting with git"
  cd "${curdir}/$LAMBDA_NAME"
  DATE_TICKS=$(date +%s)
  VERSION_SUFFIX=$DATESUFFIX-${DATE_TICKS:6:4}
  git add .
  git commit -m "v$VERSION_SUFFIX"
  git push origin master
  echo -e "Commit v$VERSION_SUFFIX"
}

get_parameter (){
  PARAMETER_NAME=$1
  
  while IFS='' read -r line || [[ -n "$line" ]]; do
    if [[ $line == *${PARAMETER_NAME}* ]]; then
      read -r line
      PARAMETER_VALUE=`echo ${line} | awk -F":" '/,/{gsub(/ /, "", $2); print substr($2,2,length($2)-3)}'`
      echo -e "found $PARAMETER_VALUE for $PARAMETER_NAME"
      return
    fi
  done < "${curdir}/${LAMBDA_NAME}/parameters.json"
}

create_lambda_dir () {
  echo -e "${YELLOW}Creating Lambda Directory for ${WHITE}${LAMBDA_NAME} ${YELLOW}using ${WHITE}${RUN_TIME}${SET}"
  mkdir $LAMBDA_NAME 
  cd $LAMBDA_NAME

  touch "${curdir}/${LAMBDA_NAME}/requirements.txt"
  cp "${curdir}/support-files/gitignore.txt" "${curdir}/${LAMBDA_NAME}/.gitignore"
  cp "${curdir}/support-files/Dockerfile.${RUN_TIME}" "${curdir}/${LAMBDA_NAME}/Dockerfile"
  cp "${curdir}/support-files/lambda.py" "${curdir}/${LAMBDA_NAME}/lambda.py"
  cp "${curdir}/support-files/template.yaml" "${curdir}/${LAMBDA_NAME}/template.yaml"
  cp "${curdir}/support-files/parameters.json" "${curdir}/${LAMBDA_NAME}/parameters.json"

  # Customizing Parameters for the function
  sed -i -E "s/@ProjectName/$(echo ${PROJECT_NAME} | sed -e 's/\\/\\\\/g; s/\//\\\//g; s/&/\\\&/g')/g" "${curdir}/${LAMBDA_NAME}/parameters.json"
  sed -i -E s/"@S3DeploymentBucketName"/"${S3_BUCKET}"/g "${curdir}/${LAMBDA_NAME}/parameters.json"
  sed -i -E "s/@S3DeploymentFileKey/$(echo ${S3_KEY}/${LAMBDA_NAMElower}-code.zip | sed -e 's/\\/\\\\/g; s/\//\\\//g; s/&/\\\&/g')/g" "${curdir}/${LAMBDA_NAME}/parameters.json"
  sed -i -E s/"@EnvironmentName"/"${LAMBDA_ENV}"/g "${curdir}/${LAMBDA_NAME}/parameters.json"
  sed -i -E s/"@Runtime"/"${RUN_TIME}"/g "${curdir}/${LAMBDA_NAME}/parameters.json"
}

build () {
  get_parameter S3DeploymentBucketName
  S3_BUCKET=$PARAMETER_VALUE
  get_parameter S3DeploymentFileKey
  S3_KEY=$PARAMETER_VALUE

  echo -e "${YELLOW}Delete zip from S3${SET}"
  aws s3 rm "s3://${S3_BUCKET}/${S3_KEY}"
  echo -e "${YELLOW}Running docker for building ${RUN_TIME}${SET}"
  cd "${LAMBDA_DIR}"
  docker build --tag $LAMBDA_NAMElower --build-arg FUNCTION_NAME=$LAMBDA_NAME .
  echo -e "${YELLOW}Copy Zip${SET}"
  docker run --rm -v $ZIP_DIR:/dest "${LAMBDA_NAMElower}:latest" cp "$LAMBDA_NAME/code.zip" "/dest/${LAMBDA_NAMElower}-${DATESUFFIX}.zip"
  echo -e "${YELLOW}Sending Zip to ${S3_BUCKET}${SET}"
  aws s3 cp "${ZIP_DIR}/${LAMBDA_NAMElower}-${DATESUFFIX}.zip" "s3://${S3_BUCKET}/${S3_KEY}"
}

update_code () {
  FUNCTION_ARN=$(aws cloudformation describe-stacks --stack-name PhourUserMig-Dev | grep "function:PhourUserMig-Dev" | awk -F":" '{print substr($8,1,length($8)-1)}')
  aws lambda update-function-code --function-name "${FUNCTION_ARN}" --s3-bucket "${S3_BUCKET}" --s3-key "${S3_KEY}"
	echo -e "${YELLOW}Lambda source code updated successfully.${SET}"
}

create_stack () {
  echo -e "${YELLOW}Creating Stack ${LAMBDA_NAME}${SET}"
	aws cloudformation create-stack \
	  --stack-name ${LAMBDA_NAME} \
	  --template-body file://template.yaml \
	  --parameters file://parameters.json \
	  --capabilities CAPABILITY_IAM
}

update_stack () {
  echo -e "${YELLOW}Updating Stack ${LAMBDA_NAME}${SET}"
  aws cloudformation update-stack \
	  --stack-name ${LAMBDA_NAME} \
	  --template-body file://template.yaml \
	  --parameters file://parameters.json \
	  --capabilities CAPABILITY_IAM
}

delete_all () {
  aws cloudformation delete-stack \
	  --stack-name ${LAMBDA_NAME}
  docker image rm $LAMBDA_NAMElower
  rm -rf $LAMBDA_NAME
}

# A string with command options
options=$@
# An array with all the arguments
arguments=($options)
# Loop index
index=0

for argument in $options
  do
    # Incrementing index
    index=`expr $index + 1`
    # The conditions
    case $argument in
      --lambda) LAMBDA_NAME="${arguments[index]}" ;;
      --region) AWS_DEFAULT_REGION="${arguments[index]}" ;;
      --delete) DELETE=true ;;
      --nogit) NOGIT=true ;;
      --new) NEW_LAMBDA=true ;;
      --runtime) RUN_TIME=${arguments[index]} ;;
      --s3bucket) S3_BUCKET=${arguments[index]} ;;
      --s3key) S3_KEY=${arguments[index]} ;;
      --prod) PROD=true ;;
      --stack) STACK_UPDATE=true ;;
    esac
  done

if [ -z "$LAMBDA_NAME" ]; then
   echo -e "Please use publish.sh --lambda <<lambdaname>> --region <<region>>"
   exit 1
fi

if [ -z "$PROD" ]; then
   LAMBDA_ENV="Dev"
else
   LAMBDA_ENV="Prod"
fi

# Setting up Variables
read curdir <<< $(pwd)
LAMBDA_DIR="${curdir}/${LAMBDA_NAME}"
LAMBDA_NAMElower=$(echo -e "$LAMBDA_NAME" | tr '[:upper:]' '[:lower:]')
ZIP_DIR="${curdir}/zipfiles"

if [ ! -z "$DELETE" ]; then
   if [[ ! -d "$LAMBDA_NAME" ]]; then
      echo -e -e "${RED}You probably have deleted this lambda. There is not directory called ${LAMBDA_NAME}${SET}"
      exit 1;
   fi
   echo -e "${YELLOW}Deleting resources${SET}"
   delete_all
   exit 0;
fi

#
# Creating all the files for BUILDING and DEPLOY if is a new lambda
#
if [ ! -z "$NEW_LAMBDA" ]; then

  PROJECT_NAME="${LAMBDA_NAME}"
  LAMBDA_NAME="${LAMBDA_NAME}-${LAMBDA_ENV}"
  LAMBDA_DIR="${curdir}/${LAMBDA_NAME}"
  LAMBDA_NAMElower=$(echo -e "$LAMBDA_NAME" | tr '[:upper:]' '[:lower:]')

  if ! aws s3api head-bucket --bucket "$S3_BUCKET" 2>/dev/null; then
    echo -e "${RED}S3 bucket ${WHITE}${S3_BUCKET} ${RED}does not exist.${SET}"
    exit 1
  fi

  if [ -z "$S3_KEY" ]; then
    echo -e "${RED}Please provide a S3 key using --s3key <<value>>${SET}"
    exit 1
  fi

  if [ -z "$RUN_TIME" ]; then
     RUN_TIME="python3.6"
  fi

  create_lambda_dir
  if [ -z "$NOGIT" ]; then
    git_init
  fi
fi
  
if [[ "$LAMBDA_NAME" == -* || "$RUN_TIME" == -* || "$S3_BUCKET" == -* || "$S3_KEY" == -* ]]; then
   echo -e "${RED}Something does not look correct in your parameters${SET}"
   exit 1
fi

if [ ! -d "$LAMBDA_DIR" ]; then
   echo -e "${RED}I couldn't find the $LAMBDA_NAME directory. Please create a new lamnbda using the --new options${SET}"
   exit 1;
fi

#
# Building
#
build

#
# Deployng to AWS
#
if [ -z "$NEW_LAMBDA" ]; then
  if [ -z "$NOGIT" ]; then
     git_sync
  fi
  if [ ! -z "$STACK_UPDATE" ]; then
     update_stack
  fi
  update_code
else
  create_stack   
fi

echo -e "${YELLOW}Function updated${SET}"
