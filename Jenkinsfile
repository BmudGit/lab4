pipeline {
    agent any

    environment {
        IMAGE_NAME = "flask-app"
        CONTAINER_NAME = "flask-app-container"
        NETWORK_NAME = "app-network"
        TRIVY_REPORT = "trivy-report.txt"
    }

    stages{

        stage("TRIVY SCAN"){
           steps {
                sh "echo "Trivy Filesystem Scan:""
                sh "trivy fs --severity HIGH,CRITICAL --exit-code 1 --format table . | tee $TRIVY_REPORT"
            } 
        }

        stage("BUILD") {
            steps {
                sh """
                docker buildx build -t $IMAGE_NAME:latest .
                """
            }
        }

        stage("TEST") {
            steps{
                timeout(time: 2, unit: "MINUTES"){
                    sh """
                    echo "Smoke test:"
                    docker run -d --rm --name $CONTAINER_NAME -p 5500:5500 $IMAGE_NAME:latest
                    sleep 5
                    curl -f http://localhost:5500 || (echo "Smoke test failed" && exit 1)
                    docker stop $CONTAINER_NAME || true
                    """
                }
            }
        }

        stage("APPROVAL") {
            steps {
                timeout(time: 10, unit: "MINUTES") {
                    input message: "Approve deployment?"
                }
            }
        }

        stage("DEPLOYMENT") {
            steps{
                sh """
                docker network rm $NETWORK_NAME || true
                docker rm -f $CONTAINER_NAME || true
                docker rm -f nginx-container || true

                echo ""
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

    post {
        failure {
            sh """
            docker network rm $NETWORK_NAME || true
            docker rm -f $CONTAINER_NAME || true
            docker rm -f nginx-container || true
            """
        }

        always {
            archiveArtifacts artifacts: "trivy-report.txt", allowEmptyArchive: true, fingerprint: true
        }
    }
}