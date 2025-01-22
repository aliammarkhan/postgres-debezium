
  

# Running Docker Containers for Postgres-Debezium-Kafka

  

  

This guide will walk you through the steps to run Docker containers for Postgres, Debezium, and Kafka, and to observe changes in a Kafka topic via Debezium.

  

  

## Prerequisites

  

  

- Docker and Docker Compose installed on your machine.

  

  

## Steps to Run the Docker Containers

  

  

-  **Run the Docker Containers**

  

To start the services, run the following command: ``` docker compose up -d ```

  

  

-  **Database Initialization**

  

The `init.sql` file will automatically create the `product` and `customer` table in the Postgres database upon container startup.

  

-  **Topics Initialization**

  We can create kafka topics using `kafka-topics` command.

``` docker exec -it <container_id> kafka-topics --bootstrap-server kafka:9092 --create --topic testdb.public.paper.topic --partitions 2 --replication-factor 1 ```

  

  

-  **Establish Debezium Connection**

  

  

After the containers are up and running, establish the Debezium connection to capture changes from the Postgres database. Run the following command:

  

```
curl -i -X POST -H "Accept:application/json" -H "Content-Type:application/json" 127.0.0.1:8083/connectors/ --data "@debezium.json"
```
This will configure Debezium to listen for changes on the `product` and `customer` table in the Postgres database.

For a CDC setup with PostgreSQL-Debezium-Kafka, you must set `wal_level = logical` because:

-   Debezium uses PostgreSQL's logical decoding feature to read changes from the WAL and convert them into a stream of events.
-   Logical decoding captures INSERT, UPDATE, DELETE operations, and provides the data in a format suitable for downstream consumers like Kafka.

We can set the WAL level to logical with the SQL command ``ALTER SYSTEM SET wal_level = logical;``

Also, if we want both the before state and after state of an event we would also need to change the table's replica identity to FULL ``ALTER TABLE public.student REPLICA IDENTITY FULL;``

`REPLICA IDENTITY` is a table-level setting in PostgreSQL that determines what information is included in the `before` state of a row during an `UPDATE` or `DELETE` operation in logical replication or logical decoding (used by Debezium).
  

  

-  **Tail Kafka Topic for Changes**

  

Once the Debezium connector is set up, you can observe changes in the Kafka topic. Run the following curl command to tail the Kafka container topic:

  

```
docker run --tty --network postgres_debezium_network confluentinc/cp-kafkacat kafkacat -b kafka:9092 -C -s key=s -t <topic_name> -p <partion_number>
```

Replace `<topic_name> ` with the name of the kafka topic defined in `debezium.json` file.

  

-  **Execute SQL Statements and Observe Changes in Kafka**

  

Now, execute SQL insert, update, and delete statements on the `customer` and `product` tables in the Postgres container. You should be able to see the changes being captured by Debezium and pushed to the Kafka topic

  

  

Use the following commands to interact with the Postgres container:

  

-  **Insert Data:**

  

``` docker exec -it 4fefbf9f784b psql -U admin -d testdb -c "INSERT INTO product (name, description) VALUES ('milk', 'creamy milk');"```

``` docker exec -it 4fefbf9f784b psql -U admin -d testdb -c "INSERT INTO customer (name, age, address) VALUES ('Ali', 28, '456 Oak Avenue');"```

  

  

-  **Delete Data:**

  

``` docker exec -it 4fefbf9f784b psql -U admin -d testdb -c "DELETE from product where name = 'milk'" ```

``` docker exec -it a331b07473c7 psql -U admin -d testdb -c "DELETE FROM customer WHERE NAME = 'Khan';" ```

  

-  **Update Data:**

  

``` docker exec -it <container_id> psql -U admin -d testdb -c "UPDATE customer SET AGE = 30 WHERE NAME = 'Jane Doe';" ```

``` docker exec -it 4fefbf9f784b psql -U admin -d testdb -c "DELETE from product where name = 'milk'" ```

  

  

You can get the postgres `<container_id>` by running the command `docker ps`. The this will list all the running containers.

-  **Message Structure**

The change event is pushed into Kafka in JSON format. We can specify which message converter to use using the ``CONNECT_KEY_CONVERTER`` and ``CONNECT_VALUE_CONVERTER`` properties. Also we can leverage the ``CONNECT_VALUE_CONVERTER_SCHEMAS_ENABLE`` and ``CONNECT_KEY_CONVERTER_SCHEMAS_ENABLE`` properties to either get the schema level details or not. Setting this to ``false`` will only push the data related changes to kafka.

```
Insert Event :

{
  "before": null,
  "after": {
    "id": 5,
    "name": "hammer",
    "description": "cricket bat",
    "create_timestamp": 1737549346157592,
    "update_timestamp": 1737549346157592
  },
  "source": {
    "version": "2.6.2.Final",
    "connector": "postgresql",
    "name": "testdb",
    "ts_ms": 1737549346158,
    "snapshot": "false",
    "db": "testdb",
    "sequence": "[\"26522096\",\"26522096\"]",
    "ts_us": 1737549346158423,
    "ts_ns": 1737549346158423000,
    "schema": "public",
    "table": "product",
    "txId": 754,
    "lsn": 26522096,
    "xmin": null
  },
  "op": "c",
  "ts_ms": 1737549346544,
  "ts_us": 1737549346544526,
  "ts_ns": 1737549346544526000,
  "transaction": null
}

Update Event :

{
  "before": {
    "id": 5,
    "name": "hammer",
    "description": "cricket bat",
    "create_timestamp": 1737549346157592,
    "update_timestamp": 1737549346157592
  },
  "after": {
    "id": 5,
    "name": "hammer",
    "description": "good",
    "create_timestamp": 1737549346157592,
    "update_timestamp": 1737549346157592
  },
  "source": {
    "version": "2.6.2.Final",
    "connector": "postgresql",
    "name": "testdb",
    "ts_ms": 1737552071957,
    "snapshot": "false",
    "db": "testdb",
    "sequence": "[\"26522304\",\"26522592\"]",
    "ts_us": 1737552071957106,
    "ts_ns": 1737552071957106000,
    "schema": "public",
    "table": "product",
    "txId": 755,
    "lsn": 26522592,
    "xmin": null
  },
  "op": "u",
  "ts_ms": 1737552072134,
  "ts_us": 1737552072134167,
  "ts_ns": 1737552072134167300,
  "transaction": null
}

Delete Event:

{
  "before": {
    "id": 5,
    "name": "hammer",
    "description": "good",
    "create_timestamp": 1737549346157592,
    "update_timestamp": 1737549346157592
  },
  "after": null,
  "source": {
    "version": "2.6.2.Final",
    "connector": "postgresql",
    "name": "testdb",
    "ts_ms": 1737552157605,
    "snapshot": "false",
    "db": "testdb",
    "sequence": "[\"26523216\",\"26523504\"]",
    "ts_us": 1737552157605094,
    "ts_ns": 1737552157605094000,
    "schema": "public",
    "table": "product",
    "txId": 756,
    "lsn": 26523504,
    "xmin": null
  },
  "op": "d",
  "ts_ms": 1737552157796,
  "ts_us": 1737552157796048,
  "ts_ns": 1737552157796048100,
  "transaction": null
}

```
-  **Message Routing**

We can route the event messages to a particular topic based on a regular expression and to a particular partition based on a change event field. In this example all the events from the ``customer`` table will be routed to the customer topic and the events from ``product`` table will be routed to the product topic. 

The topic routing is defined as:

```
"transforms.Route.regex": "testdb.public.(.*)",
"transforms.Route.replacement": "testdb.public.$1.topic",
```

And the partition routing is defined using the name field in the change event.

```
"transforms.PartitionRouting.type":"io.debezium.transforms.partitions.PartitionRouting",
"transforms.PartitionRouting.partition.payload.fields": "change.name",
"transforms.PartitionRouting.partition.topic.num": 2
```

We can also use Content based routing. An example of CBR is added in in ```debezium-CBR.json``` file. To configure CBR, we will need to copy the scripting related jar files present in ```debezium-scripting``` folder inside ```/kafka/connect/debezium-connector-postgres``` folder inside our debezium container.

You can read more about message routing here https://debezium.io/documentation/reference/stable/transformations/index.html
  

-  **Stop the Docker Containers**

  

To stop the services, run the following command: ``` docker compose down --rmi local ```
