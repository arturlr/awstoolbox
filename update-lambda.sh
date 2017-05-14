#!/bin/bash

if [[ ! -n "$1" ]]; then
   echo "Please add the project name"
   exit 1
fi

rm -r -f $1

git clone ssh://git-codecommit.us-east-1.amazonaws.com/v1/repos/$1

read curdir <<< $(pwd)
DATESUFFIX=$(date +%Y-%b-%d-%H%M)
BUCKET=phours
PREFIX=lambda
TEMPDEPLOY="${curdir}"/tempDeploy

printf "Creating the temp VirtualEnv\n"
sudo rm -r -f "${TEMPDEPLOY}"
virtualenv "${TEMPDEPLOY}"

printf "Copying Lambda project\n"
cp "${curdir}"/$1/* "${TEMPDEPLOY}"/

if [[ ! -f "${TEMPDEPLOY}"/lambda_function.py ]]; then
   echo "Could not find lambda_function.py in ${TEMPDEPLOY}"
   exit 1
fi

if [[ -f "${TEMPDEPLOY}"/code.zip ]]; then
   rm "${TEMPDEPLOY}"/code.zip
fi

## Instaling Packages
print "Installing Packages\n"
"${TEMPDEPLOY}"/bin/pip install pip -U
"${TEMPDEPLOY}"/bin/pip install -r "${TEMPDEPLOY}"/requirements.txt

printf "Add packages to the zip file\n"
cd "${TEMPDEPLOY}"/lib/python2.7/site-packages/
zip -r9q "${TEMPDEPLOY}"/code.zip *
cd "${TEMPDEPLOY}"/lib64/python2.7/site-packages/
zip -r9q "${TEMPDEPLOY}"/code.zip *

cd "${TEMPDEPLOY}"
zip -g "${TEMPDEPLOY}"/code.zip lambda_function.py

printf "Copying to S3\n"
aws s3 cp code.zip s3://"${BUCKET}"/"${PREFIX}"/$1-"${DATESUFFIX}".zip

printf "Zip Completed\n\n"

aws lambda update-function-code --function-name $1 --s3-key "${PREFIX}"/$1-"${DATESUFFIX}".zip \
   --s3-bucket "${BUCKET}" > "${TEMPDEPLOY}"/update.log

cat "${TEMPDEPLOY}"/update.log

printf "Function updated\n"

if [[ "$2" =~ "-test" ]]; then

   if [[ ! -f input.json ]]; then
      echo "Missing file ~/$1/input.json. Please add a sample event for testing"
      echo "An S3 Event example can be fount at: http://docs.aws.amazon.com/lambda/latest/dg/with-s3-example-upload-deployment-pkg.html"
      exit 1
   fi
   read rsp <<< $(cat update.log | awk '/FunctionArn/ {print $2}')
   printf "Testing ${rsp:1:-2}\n\n"
   aws lambda invoke --function-name "${rsp:1:-2}" \
   --invocation-type RequestResponse \
   --log-type Tail \
   --payload file://"${TEMPDEPLOY}"/input.json "${TEMPDEPLOY}"/output.log > "${TEMPDEPLOY}"/logresult.json
   read logresult <<< $(cat "${TEMPDEPLOY}"/logresult.json | awk '/LogResult/ {print $2}')
   echo "${logresult:1:-2}" | base64 --decode
   printf "\n"
   cat "${TEMPDEPLOY}"/output.log
   printf "\n"

fi
