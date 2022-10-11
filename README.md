# Tiered Storage Demo

This demo walks through how to get started with Tiered Storage in Confluent Platform 6.0. Docker must be installed and running.

For more information:

* [Link to documentation](https://docs.confluent.io/current/kafka/tiered-storage.html)


# Run the Demo

## Requirements

* AWS CLI configured to properly pull from ECS
* An S3 bucket

### Start a Broker with Tiered Storage Enabled


1. Run docker compose
`$ docker-compose up` or `$ docker-compuse up -d` if you'd like to hide the output and run in the background

2. Confluent Control Center will be available at localhost:9021


## Create a Topic

To observe the results of the demo within a reasonable time frame, we create a topic with a short hotset (1 minute), a short retention period (10 minutes), and smaller log segments (100 MB). These configurations were passed to the broker through the [docker-compose.yml](docker-compose.yml) file. Messages that are produced to this topic will be uploaded to the specified S3 bucket.

```
 kafka-topics \
    --bootstrap-server localhost:9091 \
    --create \
    --topic test-topic \
    --partitions 1
```

Additionally, you can create a topic through Confluent Control Center and configure Tiered Storage from there.

<kbd><img src="images/c3-ts-settings.png" /></kbd>

## Produce Messages to the Topic

After creating the topic, we should produce enough messages to the topic to ensure that log segments will fill to the 100MB limit and be uploaded to the S3 bucket.

```
kafka-producer-perf-test --topic test-topic \
    --num-records 5000000 \
    --record-size 5000 \
    --throughput -1 \
    --producer-props \
        acks=all \
        bootstrap.servers=localhost:9091 \
        batch.size=8196
```
After a short wait, we should see files beginning to appear in the S3 bucket. You may notice the top directory of "0" appearing first.

<kbd><img src="images/top-dir.png" /></kbd>

Navigating into the directory, we should see more sub-directories that each correspond to a specific log segment:

<kbd><img src="images/all-segment-dirs.png" /></kbd>

## Consume Messages

Because the topic has a short hotset period, log segments that are uploaded to the S3 bucket will not remain on disk for long. The log segments with the earliest offsets will start to be deleted from disk, since a copy of them resides in object storage. We can still consume these messages that now reside only in the S3 bucket. We can create a consumer that is configured to read messages from the beginning of the topic:

```
kafka-consumer-perf-test --topic multi-region-async \
    --messages 5000 \
    --threads 1 \
    --broker-list localhost:9091 \
    --timeout 20000 \
    --consumer.config config/consumer.config
```

## Monitoring Tiered Storage

It is likely that there is no obvious difference between reading messages delivered from the S3 bucket versus reading messages from log segments on disk. We can query metrics from the broker to verify that the consumer was reading messages delivered from the broker.

You can monitor various Tiered Storage metrics through the C3 dashboard

<kbd><img src="images/ts-metrics.png" /></kbd>

