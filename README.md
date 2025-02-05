
# Running Docker Containers for Postgres-Debezium-Kafka

This guide will walk you through the steps to run Docker containers for Postgres, Debezium, and Kafka, and to observe changes in a Kafka topic via Debezium.

## Prerequisites

- Docker and Docker Compose installed on your machine.

## Steps to Run the Docker Containers

 - **Run the Docker Containers**
To start the services, run the following command: ``` docker compose up -d ```

 - **Database Initialization**
The `init.sql` file will automatically create the `student` table in the Postgres database upon container startup.

 - **Establish Debezium Connection**

	After the containers are up and running, establish the Debezium connection to capture changes from the Postgres database. Run the following command:
	``` 
	curl -i -X POST -H "Accept:application/json" -H "Content-Type:application/json" \
	127.0.0.1:8083/connectors/ --data "@debezium.json" 
	``` 
	This will configure Debezium to listen for changes on the `student` table in the Postgres database.

 - **Tail Kafka Topic for Changes**
	Once the Debezium connector is set up, you can observe changes in the Kafka topic. Run the following curl command to tail the Kafka container topic:
	```
	docker run --tty --network postgres_debezium_network confluentinc/cp-kafkacat kafkacat -b kafka:9092 -C -s key=s -t testdb.public.student
	```
 - **Execute SQL Statements and Observe Changes in Kafka**
Now, execute SQL insert, update, and delete statements on the `student` table in the Postgres container. You should be able to see the changes being captured by Debezium and pushed to the Kafka topic.
	

	Use the following commands to interact with the Postgres container:
	 - **Insert Data:**
			``` docker exec -it <container_id> psql -U admin -d testdb -c "INSERT INTO Student (name, age, address) VALUES ('Khan', 28, '456 Oak Avenue');" ```

	- **Delete Data:**
			``` docker exec -it <container_id> psql -U admin -d testdb -c "DELETE FROM Student WHERE NAME = 'Khan';" ```
	- **Update Data:**
	  			``` docker exec -it <container_id> psql -U admin -d testdb -c "UPDATE Student SET AGE = 30 WHERE NAME = 'Jane Doe';" ```

	You can get the postgres `<container_id>`  by running the command `docker ps`. The this will list all the running containers.'
	
 - **Message Transformation and initial db snapshot.**
	After establishing the debezium connection, debezium will capture all the changes from that point in time. If we also want to get the current table data, We can use this property in debezium.json file 		```"snapshot.mode": "initial",```.
	
	Also If we want to perform message transformation, like changing the field name or the message structure we can use event flattening transformation.
	
	```
	transforms=unwrap,... 
	transforms.unwrap.type=io.debezium.transforms.ExtractNewRecordState
	```
	
	To change the field name ```org.apache.kafka.connect.transforms.ReplaceField$Value```  SMT. The following properties will flatten the data, change field name and include metadata fields in the final message 		structure.
	
	```
	"snapshot.mode": "initial",
	"transforms": "Route,unwrap,rename",
	"transforms.Route.type": "org.apache.kafka.connect.transforms.RegexRouter",
	"transforms.Route.regex": ".*",
	"transforms.Route.replacement": "hello-world-topic",
	"transforms.unwrap.type": "io.debezium.transforms.ExtractNewRecordState",
	"transforms.unwrap.add.fields": "op,table,lsn,source.ts_ms",
	"transforms.rename.type": "org.apache.kafka.connect.transforms.ReplaceField$Value",
	"transforms.rename.renames": "name:first_name,address:current_address"
	```
	
	JSON before transformation:
	
	```
	{
	  "before": null,
	  "after": {
	    "id": 1,
	    "name": "Khan",
	    "age": 28,
	    "address": "456 Oak Avenue",
	    "create_timestamp": 1738787171494371,
	    "update_timestamp": 1738787171494371
	  },
	  "source": {
	    "version": "2.6.2.Final",
	    "connector": "postgresql",
	    "name": "testdb",
	    "ts_ms": 1738787214832,
	    "snapshot": "last",
	    "db": "testdb",
	    "sequence": "[null,\"27303136\"]",
	    "ts_us": 1738787214832374,
	    "ts_ns": 1738787214832374000,
	    "schema": "public",
	    "table": "student",
	    "txId": 740,
	    "lsn": 27303136,
	    "xmin": null
	  },
	  "op": "r",
	  "ts_ms": 1738787215414,
	  "ts_us": 1738787215414438,
	  "ts_ns": 1738787215414439000,
	  "transaction": null
	}
	```
	
	JSON After:
	
	```
	{
	  "id": 1,
	  "first_name": "Khan",
	  "age": 28,
	  "current_address": "456 Oak Avenue",
	  "create_timestamp": 1738786115080473,
	  "update_timestamp": 1738786115080473,
	  "__op": "r",
	  "__table": "student",
	  "__lsn": 27184248,
	  "__source_ts_ms": 1738786196126
	}
	
	```

 - **Stop the Docker Containers**
To stop the services, run the following command: ``` docker compose down --rmi local ```
