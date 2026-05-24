pipeline {
    agent any

    environment {
        SONAR_SERVER = 'sonarqube-server'
        SONAR_ORGANIZATION = 'solunmanrique'
        NODE_IMAGE = 'node:14.21.3-bullseye'
        NPM_VERSION = '8.19.4'
        SONAR_SCANNER_IMAGE = 'sonarsource/sonar-scanner-cli:5.0.1'
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
                    image "${env.NODE_IMAGE}"
                    args '-u root'
                }
            }
            steps {
                sh "npm install -g npm@${env.NPM_VERSION}"
                sh 'npm ci'
            }
        }

        stage('Compilar Angular') {
            agent {
                docker {
                    image "${env.NODE_IMAGE}"
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
                    image "${env.SONAR_SCANNER_IMAGE}"
                    args '--entrypoint="" -u root'
                }
            }
            steps {
                withSonarQubeEnv("${env.SONAR_SERVER}") {
                    sh """
                        sonar-scanner \
                        -Dsonar.host.url=${env.SONAR_HOST_URL} \
                        -Dsonar.login=${env.SONAR_AUTH_TOKEN} \
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

