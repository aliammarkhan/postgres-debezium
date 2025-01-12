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

	You can get the postgres `<container_id>`  by running the command `docker ps`. The this will list all the running containers.

 - **Stop the Docker Containers**
To stop the services, run the following command: ``` docker compose down --rmi local ```
			  
			   		
