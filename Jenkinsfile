pipeline {
    agent any
    
    environment {
        HARBOR_URL = 'nginx'
        HARBOR_PROJECT = 'hotel-reservation'
        GITEA_URL = 'https://gitea.com/sridharreddy7093/hotel-reservation-mgnt.git'
    }
    
    stages {
        stage('Checkout from Gitea') {
            steps {
                git branch: 'main',
                    url: "${GITEA_URL}",
                    credentialsId: 'gitea-credentials'
            }
        }
        
        stage('Build Backend Docker Image') {
            steps {
                sh 'docker build -t hotel-reservation-backend:${BUILD_NUMBER} ./backend'
            }
        }
        
        stage('Build Frontend Docker Image') {
            steps {
                sh 'docker build -t hotel-reservation-frontend:${BUILD_NUMBER} ./frontend'
            }
        }
        
        stage('Push to Harbor') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'harbor-credentials',
                    usernameVariable: 'HARBOR_USER',
                    passwordVariable: 'HARBOR_PASS'
                )]) {
                    sh """
                        echo ${HARBOR_PASS} | docker login ${HARBOR_URL} -u ${HARBOR_USER} --password-stdin
                        docker tag hotel-reservation-backend:${BUILD_NUMBER} ${HARBOR_URL}/${HARBOR_PROJECT}/hotel-reservation-backend:${BUILD_NUMBER}
                        docker tag hotel-reservation-frontend:${BUILD_NUMBER} ${HARBOR_URL}/${HARBOR_PROJECT}/hotel-reservation-frontend:${BUILD_NUMBER}
                        docker push ${HARBOR_URL}/${HARBOR_PROJECT}/hotel-reservation-backend:${BUILD_NUMBER}
                        docker push ${HARBOR_URL}/${HARBOR_PROJECT}/hotel-reservation-frontend:${BUILD_NUMBER}
                    """
                }
            }
        }
        
        stage('Deploy to Production') {
            steps {
                sh """
                    docker-compose pull
                    docker-compose up -d
                """
            }
        }
    }
    
    post {
        success {
            echo 'Deployment successful!'
        }
        failure {
            echo 'Deployment failed!'
        }
    }
}