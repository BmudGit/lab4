pipeline {
    agent any

    environment {
        IMAGE_NAME = 'flask-app'
        CONTAINER_NAME = "flask-app-container"
        NETWORK_NAME = "app-network"
        TRIVY_REPORT = "trivy-report.txt"
    }

    stages{

        stage("CLEANUP") {
            steps{
                cleanWs()

                sh """
                docker network rm $NETWORK_NAME || true
                docker rm -f $CONTAINER_NAME || true
                docker rm -f nginx-container || true
                """
            }
        }

        stage("BULID") {
            steps {
                sh """
                docker buildx build -t $IMAGE_NAME:latest .
                """
            }
        }

        stage("TEST") {
            steps{
                sh """
                echo "Smoke test:
                docker run -d --rm --name $CONTAINER_NAME -p 5500:5500 $IMAGE_NAME:latest
                sleep 5
                curl -f http://localhost:5500 || (echo "Smoke test failed" && exit 1)
                docker stop $CONTAINER_NAME || true

                echo ""
                echo "Trivy Scan:"
                docker run -rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy image --format table $IMAGE_NAME:latest > $TRIVY_REPORT
                cat $TRIVY_REPORT
                """

                echo ""
                echo "Archiving scan results"
                archiveArtifacts artifacts: 'trivy-report.txt', fingerprint: true

                script{
                    input message: "Approve deployment?"
                }
            }
        }

        stage("DEPLOYMENT") {
            steps{
                sh """
                echo""
                echo "Creating docker network"
                docker network create $NETWORK_NAME || true

                echo ""
                echo "Running flask container"
                docker run -d --name $CONTAINER_NAME --network $NETWORK_NAME $IMAGE_NAME:latest

                echo ""
                echo "Running Nginx container"
                docker run -d --name nginx-container --network $NETWORK_NAME -p 80:80 -v \$(pwd)/nginx.conf:/etc/nginx/nginx.conf:ro nginx:latest
                """
            }
        }
    }
}