pipeline {
    agent any

    environment {
        DOCKER_REGISTRY = 'registry.homelab.local:5000'
        APP_NAME = 'myapp'
        SLACK_CHANNEL = '#deployments'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
                script {
                    env.GIT_COMMIT_SHORT = sh(
                        script: 'git rev-parse --short HEAD',
                        returnStdout: true
                    ).trim()
                    env.IMAGE_TAG = "${env.APP_NAME}:${env.GIT_COMMIT_SHORT}"
                }
            }
        }

        stage('Build') {
            steps {
                sh """
                    docker build \
                        --build-arg BUILD_DATE=\$(date -u +'%Y-%m-%dT%H:%M:%SZ') \
                        --build-arg VCS_REF=${env.GIT_COMMIT_SHORT} \
                        -t ${env.DOCKER_REGISTRY}/${env.IMAGE_TAG} \
                        -t ${env.DOCKER_REGISTRY}/${env.APP_NAME}:latest \
                        .
                """
            }
        }

        stage('Test') {
            steps {
                sh """
                    docker run --rm \
                        ${env.DOCKER_REGISTRY}/${env.IMAGE_TAG} \
                        python -m pytest tests/ -v --tb=short
                """
            }
        }

        stage('Push') {
            steps {
                sh """
                    docker push ${env.DOCKER_REGISTRY}/${env.IMAGE_TAG}
                    docker push ${env.DOCKER_REGISTRY}/${env.APP_NAME}:latest
                """
            }
        }

        stage('Deploy to Staging') {
            steps {
                sh './scripts/deploy.sh staging ${IMAGE_TAG}'
            }
        }

        stage('Health Check') {
            steps {
                script {
                    def healthy = false
                    for (int i = 0; i < 10; i++) {
                        def status = sh(
                            script: 'curl -s -o /dev/null -w "%{http_code}" http://staging.homelab.local/healthz',
                            returnStdout: true
                        ).trim()
                        if (status == '200') {
                            healthy = true
                            break
                        }
                        sleep(time: 3, unit: 'SECONDS')
                    }
                    if (!healthy) {
                        error('Health check failed after 30 seconds')
                    }
                }
            }
        }

        stage('Deploy to Production') {
            when {
                branch 'main'
            }
            steps {
                sh './scripts/deploy.sh production ${IMAGE_TAG}'
                sh './scripts/blue-green-swap.sh'
            }
        }
    }

    post {
        success {
            slackSend(
                channel: env.SLACK_CHANNEL,
                color: 'good',
                message: "Deployed ${env.IMAGE_TAG} to production"
            )
        }
        failure {
            sh './scripts/rollback.sh'
            slackSend(
                channel: env.SLACK_CHANNEL,
                color: 'danger',
                message: "Deploy FAILED for ${env.IMAGE_TAG} — rolled back"
            )
        }
    }
}
