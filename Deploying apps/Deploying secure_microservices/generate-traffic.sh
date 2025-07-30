#!/bin/bash
for i in {1..100}; do
  curl -s "http://${GATEWAY_URL}/productpage" > /dev/null
  echo "Request $i completed"
  sleep 2
done