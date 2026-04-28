pipeline {
    agent any
    
    options {
        skipDefaultCheckout(true)
    }

    environment {
        IMAGE_NAME = 'flask-app'
        IMAGE_TAG = "${BUILD_NUMBER}"
        CONTAINER_NAME = 'flask-app'
        NETWORK_NAME = 'app-network'
        DOCKERHUB_CREDENTIALS = credentials('dockerhub')
        DOCKERHUB_REPO = 'bmud/jenkins'
    }

    stages{

        stage('SETUP') {
            steps{
                checkout scm
                sh """
                docker network rm $NETWORK_NAME || true
                docker rm -f $CONTAINER_NAME || true
                docker rm -f nginx-container || true
                """
            }
        }

        stage('TRIVY SCAN') {
           steps {
                sh "echo 'Trivy Filesystem Scan:'"
                sh "trivy fs --format json -o trivy-report.json ."
            }
        }

        stage('BUILD') {
            steps {
                sh """
                docker buildx build -t $IMAGE_NAME:latest .
                """
            }
        }

        stage('TEST') {
            steps{
                timeout(time: 2, unit: 'MINUTES') {
                    sh """
                    echo 'Smoke test:'
                    docker run -d --rm --name $CONTAINER_NAME -p 5500:5500 $IMAGE_NAME:latest
                    sleep 5
                    curl -f http://localhost:5500 || (echo 'Smoke test failed' && exit 1)
                    python3 -m pip install requests -q --break-system-packages
                    python3 -m unittest -v test_app.py
                    docker stop $CONTAINER_NAME || true
                    """
                }
            }
        }

        stage('APPROVAL') {
            steps {
                timeout(time: 10, unit: 'MINUTES') {
                    input message: 'Approve deployment?'
                }
            }
        }

        stage('PUSH IMAGE') {
            steps {
                sh """
                    echo "$DOCKERHUB_CREDENTIALS_PSW" | docker login -u "$DOCKERHUB_CREDENTIALS_USR" --password-stdin

                    docker tag ${IMAGE_NAME} ${DOCKERHUB_REPO}:${IMAGE_TAG}
                    docker tag ${IMAGE_NAME} ${DOCKERHUB_REPO}:latest

                    docker push ${DOCKERHUB_REPO}:${IMAGE_TAG}
                    docker push ${DOCKERHUB_REPO}:latest
                """
            }
        }

        stage('DEPLOYMENT') {
            steps{
                sh """
                echo 'Creating docker network'
                docker network create $NETWORK_NAME || true

                echo 'Running flask container'
                docker run -d --name $CONTAINER_NAME --network $NETWORK_NAME $IMAGE_NAME:latest

                echo 'Running Nginx container'
                docker run -d --name nginx-container --network $NETWORK_NAME -p 80:80 -v \$(pwd)/nginx.conf:/etc/nginx/nginx.conf:ro nginx:latest
                """
            }
        }
    }

    post {
        failure {
            sh """
            docker rm -f $CONTAINER_NAME || true
            docker rm -f nginx-container || true
            docker network rm $NETWORK_NAME || true
            """
        }

        always {
            archiveArtifacts artifacts: 'trivy-report.json', allowEmptyArchive: true
        }
    }
}