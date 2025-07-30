#!/bin/bash

echo "Generating normal API traffic..."
for i in {1..5}; do
    curl -s http://localhost:8080/api/v1/users > /dev/null
    sleep 1
done

echo "Generating high-rate traffic to trigger alerts..."
for i in {1..50}; do
    curl -s http://localhost:8080/api/v1/users > /dev/null &
done
wait

echo "Generating unauthorized access attempts..."
for i in {1..10}; do
    curl -s http://localhost:8080/api/v1/login > /dev/null
    sleep 0.5
done

echo "Traffic generation complete!"