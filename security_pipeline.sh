#!/bin/bash

set -e

echo "==============================="
echo "Starting DevSecOps Security Pipeline"
echo "==============================="

# Load environment variables
if [ -f .env ]; then
  export $(grep -v '^#' .env | xargs)
fi

IMAGE_NAME=${IMAGE_NAME:-ai-service}
TAG=${IMAGE_TAG:-latest}
COSIGN_KEY=${COSIGN_KEY_PATH:-cosign.key}

echo "Using Image: $IMAGE_NAME:$TAG"

echo "---------------------------------"
echo "1️⃣ Running SAST (Bandit)"
echo "---------------------------------"

bandit -r . -f json -o sast-report.json || true
echo "SAST report generated"

echo "---------------------------------"
echo "2️⃣ Running SCA (Trivy FS Scan)"
echo "---------------------------------"

trivy fs . --format json --output sca-report.json || true
echo "SCA report generated"

echo "---------------------------------"
echo "3️⃣ Generating SBOM"
echo "---------------------------------"

syft dir:. -o json > sbom.json
echo "SBOM generated"

echo "---------------------------------"
echo "4️⃣ Building Docker Image"
echo "---------------------------------"

docker build -t $IMAGE_NAME:$TAG .
echo "Docker image built"

echo "---------------------------------"
echo "5️⃣ Running Container Scan"
echo "---------------------------------"

trivy image --severity HIGH,CRITICAL --format json \
--output container-scan.json $IMAGE_NAME:$TAG || true

echo "Container scan complete"

echo "---------------------------------"
echo "6️⃣ Blocking deployment if CRITICAL found"
echo "---------------------------------"

CRITICAL=$(grep -o "CRITICAL" container-scan.json | wc -l)

if [ "$CRITICAL" -gt 0 ]; then
  echo "❌ CRITICAL vulnerabilities found: $CRITICAL"
  exit 1
fi

echo "---------------------------------"
echo "7️⃣ Signing Container Image"
echo "---------------------------------"

COSIGN_PASSWORD=$COSIGN_PASSWORD cosign sign --key $COSIGN_KEY $IMAGE_NAME:$TAG

echo "Image signed successfully"

echo "==============================="
echo "Security Pipeline Completed"
echo "==============================="