pipeline {
    agent any

    environment {
        SONAR_SERVER = 'sonarqube-server'
        SONAR_ORGANIZATION = 'solunmanrique'
        NODE_IMAGE = 'node:14.21.3-bullseye'
        NPM_VERSION = '8.19.4'
        SONAR_NODE_IMAGE = 'node:24-bookworm'
        SONAR_SCANNER_VERSION = '5.0.1.3006'
        DOCKERHUB_CREDENTIALS = 'dockerhub-credentials'
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

        stage('Build y Sonar en paralelo') {
            parallel {
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
                            image "${env.SONAR_NODE_IMAGE}"
                            args '-u root'
                        }
                    }
                    steps {
                        withSonarQubeEnv("${env.SONAR_SERVER}") {
                            sh '''
                                apt-get update
                                apt-get install -y --no-install-recommends openjdk-17-jre-headless curl unzip
                                curl -sSLo /tmp/sonar-scanner.zip "https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-${SONAR_SCANNER_VERSION}-linux.zip"
                                unzip -q /tmp/sonar-scanner.zip -d /opt
                                export PATH="/opt/sonar-scanner-${SONAR_SCANNER_VERSION}-linux/bin:${PATH}"

                                sonar-scanner \
                                -Dsonar.host.url="${SONAR_HOST_URL}" \
                                -Dsonar.token="${SONAR_AUTH_TOKEN}" \
                                -Dsonar.organization="${SONAR_ORGANIZATION}" \
                                -Dsonar.projectKey="${REPO_NAME}" \
                                -Dsonar.projectName="${REPO_NAME}" \
                                -Dsonar.sources=src \
                                -Dsonar.exclusions=**/node_modules/**,**/dist/**,**/*.spec.ts \
                                -Dsonar.coverage.exclusions=**/* \
                                -Dsonar.nodejs.executable="$(command -v node)"
                            '''
                        }
                    }
                }
            }
        }

        stage('Quality Gate') {
            steps {
                waitForQualityGate abortPipeline: true
            }
        }

        stage('Construir imagen Docker') {
            steps {
                script {
                    withCredentials([usernamePassword(
                        credentialsId: "${env.DOCKERHUB_CREDENTIALS}",
                        usernameVariable: 'DOCKERHUB_USER',
                        passwordVariable: 'DOCKERHUB_PASSWORD'
                    )]) {
                        env.DOCKER_IMAGE = "${DOCKERHUB_USER}/${env.REPO_NAME}"
                    }

                    sh '''
                        docker build \
                        -t "${DOCKER_IMAGE}:${BUILD_NUMBER}" \
                        -t "${DOCKER_IMAGE}:latest" \
                        .
                    '''
                }
            }
        }

        stage('Publicar en Docker Hub') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: "${env.DOCKERHUB_CREDENTIALS}",
                    usernameVariable: 'DOCKERHUB_USER',
                    passwordVariable: 'DOCKERHUB_PASSWORD'
                )]) {
                    sh '''
                        echo "${DOCKERHUB_PASSWORD}" | docker login -u "${DOCKERHUB_USER}" --password-stdin
                        docker push "${DOCKER_IMAGE}:${BUILD_NUMBER}"
                        docker push "${DOCKER_IMAGE}:latest"
                    '''
                }
            }
        }
    }

    post {
        always {
            sh 'docker logout || true'
        }
        failure {
            echo 'El analisis de SonarQube fallo o el Quality Gate no se cumplio.'
        }
    }
}
