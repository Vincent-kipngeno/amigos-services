#!/bin/bash

# run in the terminal using command: $ bash deploy.sh

# Step 1: Start Minikube
minikube start

# Step 2: Set the Docker environment for Minikube
eval $(minikube docker-env)

# Step 3: Build Docker Images for Microservices
# microservices=("microservice1" "microservice2" "microservice3")

# @Id
#    @SequenceGenerator(
#            name = "customer_id_sequence",
#            sequenceName = "customer_id_sequence"
#    )
#    @GeneratedValue(
#            strategy = GenerationType.SEQUENCE,
#            generator = "customer_id_sequence"
#    )

# for service in "${microservices[@]}"
# do
#  echo "Building Docker image for $service"
#  cd $service
#  mvn clean install
#  docker build -t $service .
#  cd ..
# done

mvn clean install -Pbuild-docker-image

# Step 4: Apply Kubernetes Configurations for Microservices
microservices=("customer" "fraud" "notification")

for service in "${microservices[@]}"
do
  echo "Applying Kubernetes configurations for $service"
  kubectl apply -f k8s/minikube/services/${service}/deployment.yml
  kubectl apply -f k8s/minikube/services/${service}/service.yml
done

# Step 5: Apply Bootstrap Configurations
bootstrap_services=("zipkin" "postgres" "rabbitmq")
bootstrap_files=("configmap" "service" "statefulset" "volume" "rbac")

for service in "${bootstrap_services[@]}"
do
  echo "Applying Kubernetes configurations for $service"
  for cs_file in "${bootstrap_files[@]}"
  do
    config_file="k8s/minikube/bootstrap/${service}/${cs_file}.yml"

    # Check if the file exists before applying
    if [ -e "$config_file" ]; then
      kubectl apply -f "$config_file"
    else
      echo "Warning: Configuration file $config_file does not exist. Skipping..."
    fi
  done
done

# Step 6: Verify Deployments
kubectl get pods
kubectl get services

kubectl exec -it postgres-0 -- psql -U vincent

minikube service customer --url

#/*
#  CREATE DEFINER=`ewrsdevu1`@`%` PROCEDURE `GenerateCustomID`(IN tableName VARCHAR(255), IN idName VARCHAR(255), OUT custom_id VARCHAR(20))
#  BEGIN
#      DECLARE prefix CHAR(1);
#      DECLARE suffix CHAR(3);
#      DECLARE digits1 CHAR(1);
#      DECLARE digits2 CHAR(1);
#      DECLARE digits3 CHAR(1);
#      DECLARE mid_letter CHAR(1);
#      DECLARE digit_mid CHAR(1);
#      DECLARE letter_end CHAR(1);
#      DECLARE digit_end1 CHAR(1);
#      DECLARE digit_end2 CHAR(1);
#      DECLARE new_id VARCHAR(20);
#
#      DECLARE is_unique BOOLEAN DEFAULT FALSE;
#
#      WHILE NOT is_unique DO
#          SET prefix = CHAR(FLOOR(1 + RAND() * 9) + 48); -- Random digit
#          SET suffix = CHAR(FLOOR(1 + RAND() * 9) + 48); -- Random digit
#          SET digits1 = CHAR(FLOOR(1 + RAND() * 9) + 48); -- Random digit
#          SET digits2 = CHAR(FLOOR(1 + RAND() * 9) + 48); -- Random digit
#          SET digits3 = CHAR(FLOOR(1 + RAND() * 9) + 48); -- Random digit
#          SET mid_letter = CHAR(FLOOR(0 + RAND() * 25) + 65); -- Random letter
#          SET digit_mid = CHAR(FLOOR(1 + RAND() * 9) + 48); -- Random digit
#          SET letter_end = CHAR(FLOOR(0 + RAND() * 25) + 65); -- Random letter
#          SET digit_end1 = CHAR(FLOOR(1 + RAND() * 9) + 48); -- Random digit
#          SET digit_end2 = CHAR(FLOOR(1 + RAND() * 9) + 48); -- Random digit
#
#          SET new_id = CONCAT(prefix, mid_letter, digits1, digits2, digits3, mid_letter, digit_mid, letter_end, digit_end1, digit_end2);
#
#          -- Check for uniqueness
#          SET @sql = CONCAT('SELECT 1 FROM ', tableName, ' WHERE ', idName, ' = ?');
#          PREPARE stmt FROM @sql;
#          SET @param1 = new_id;
#          EXECUTE stmt USING @param1;
#          DEALLOCATE PREPARE stmt;
#
#          IF NOT FOUND_ROWS() THEN
#              SET is_unique = TRUE;
#          END IF;
#      END WHILE;
#
#      SET custom_id = new_id;
#  END
# */