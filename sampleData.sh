#!/bin/bash

# Function to generate a random key of specific length
generate_random_key() {
  dd if=/dev/urandom bs=196609 count=1 | base64 ; echo ''
}

# Total number of records
num_records=1000

# Size of each record
record_size=1000

# Size of the constant value
constant_value="This is a constant value."

# Topic to send the messages
topic=compact-topic

# Path to the producer properties file
producer_properties=producer.properties

# Loop to send messages with random keys
for ((i=0; i<num_records; i++))
do
  random_key=$(uuidgen)  # Generates a random key using uuidgen
  echo "Sending message with random key: $random_key and random value"
  random=$(dd if=/dev/urandom bs=98304 count=1 2>/dev/null | base64)
  echo "$random_key,$random" | \
  kafka-console-producer --broker-list localhost:9091 --topic $topic --property "parse.key=true" --property "key.separator=,"  >/dev/null
done
