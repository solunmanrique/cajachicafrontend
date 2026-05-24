pipeline {
    agent any

    environment {
        SONAR_SERVER = 'sonarqube-server'
        SONAR_ORGANIZATION = 'solunmanrique'
    }

    stages {
        stage('Preparar variables') {
            steps {
                script {
                    def repositoryUrl = env.GIT_URL ?: sh(
                        script: 'git config --get remote.origin.url',
                        returnStdout: true
                    ).trim()

                    env.REPO_NAME = repositoryUrl.tokenize('/').last().replaceFirst(/\.git$/, '')
                    echo "Repositorio detectado: ${env.REPO_NAME}"
                }
            }
        }

        stage('Instalar dependencias') {
            agent {
                docker {
                    image 'node:14-bullseye'
                    args '-u root'
                }
            }
            steps {
                sh 'npm ci'
            }
        }

        stage('Compilar Angular') {
            agent {
                docker {
                    image 'node:14-bullseye'
                    args '-u root'
                }
            }
            steps {
                sh 'npm run build -- --configuration production'
            }
        }

        stage('Analisis SonarQube') {
            agent {
                docker {
                    image 'node:14-bullseye'
                    args '-u root'
                }
            }
            steps {
                withSonarQubeEnv("${env.SONAR_SERVER}") {
                    sh """
                        npx sonar-scanner \
                        -Dsonar.organization=${env.SONAR_ORGANIZATION} \
                        -Dsonar.projectKey=${env.REPO_NAME} \
                        -Dsonar.projectName=${env.REPO_NAME} \
                        -Dsonar.sources=src \
                        -Dsonar.exclusions=**/node_modules/**,**/dist/**,**/*.spec.ts \
                        -Dsonar.qualitygate.wait=true
                    """
                }
            }
        }

        stage('Quality Gate') {
            steps {
                waitForQualityGate abortPipeline: true
            }
        }
    }

    post {
        failure {
            echo 'El analisis de SonarQube fallo o el Quality Gate no se cumplio.'
        }
    }
}
