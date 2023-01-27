pipeline {
    agent { label 'linux' }

    options {
        ansiColor('xterm')
    }

    environment {
        IMAGE_NAME = "aob"
        IMAGE = "admpresales/$IMAGE_NAME"
        MS_URL = credentials('teams-webhook-url')
        MS_URL_RELEASE = credentials('teams-webhook-release')
    }

    parameters {
        booleanParam(
                name: 'PUSH',
                defaultValue: false,
                description: 'Push image to Docker Hub'
        )

        booleanParam(
                name: 'SILENTRELEASE',
                defaultValue: false,
                description: 'Release without notification'
        )

        booleanParam(
                name: 'NO_CACHE',
                defaultValue: false,
                description: 'Disable caching'
        )

        string(
                name: 'TAG',
                defaultValue: '',
                description: 'Set the tag name to be built and pushed'
        )

    }

    stages {
        stage('Notify Start') {
            steps {
                script {
                    if (params.TAG == '')  {
                        if (BRANCH_NAME == "main") {
                            TAG="latest"
                        }
                        else {
                            TAG=BRANCH_NAME
                        }
                    } else {TAG=params.TAG}
                }
                script {
                    office365ConnectorSend(
                            color:  (currentBuild.previousBuild?.result == 'SUCCESS') ? '00FF00' : 'FF0000',
                            message: "Build ${currentBuild.displayName} triggered by ${currentBuild.buildCauses[0].shortDescription}",
                            webhookUrl: "${env.MS_URL}",
                            status: "Building"
                    )
                }
            }
        }

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build Dev Config') {
            when {
                expression { !params.PUSH && !TAG.equals("latest") }
            }
            steps {
                withCredentials([usernamePassword(credentialsId: 'docker-hub-nimbusbuildserver', passwordVariable: 'HUB_PASS', usernameVariable: 'HUB_USER')]) {
                    sh 'docker login --username "$HUB_USER" --password-stdin <<< $HUB_PASS'
                    sh "sed -i -e \"s,<version>,${TAG}-dev,g\" ${IMAGE_NAME}.dockerapp"
                    sh "sed -i -e \"s,<tag>,${TAG},g\" ${IMAGE_NAME}.dockerapp"
                    sh "cat ${IMAGE_NAME}.dockerapp"
                    sh "docker-app validate ${IMAGE_NAME}.dockerapp"
                    sh "docker-app push ${IMAGE_NAME}.dockerapp"
                    sh "nimbusapp ${IMAGE}:${TAG}-dev render"
                }
            }
        }

        stage('Pull Images') {
            when {
                expression { !params.PUSH && !TAG.equals("latest") }
            }
            steps {
                withCredentials([usernamePassword(credentialsId: 'dockerhub-advantageonlineshoppingapp', passwordVariable: 'HUB_PASS', usernameVariable: 'HUB_USER')]) {
                    sh label: "Docker Login", script: 'docker login --username "$HUB_USER" --password-stdin <<< $HUB_PASS'
                    sh label: "Pull AOB Images", script: "docker-app render -s REPO_NAME=advantageonlineshopping admpresales/${IMAGE_NAME}.dockerapp:${TAG}-dev | docker-compose -p aob -f - pull"
                    sh label: 'Add Admpresales Tags', script: '''
                        IMAGES=`nimbusapp aob -s REPO_NAME=advantageonlineshopping render |  grep '^[[:space:]]*image' |  sed 's/image://' | sort`
                        IFS=' ' read -r -a array <<< "$IMAGES"
                        for element in "${array[@]}"
                        do
                            echo "$element"
                        done

                    '''
                }
            }
        }
        stage('Push') {
            when {
                expression { params.PUSH && !TAG.equals("latest") }
            }
            steps {
                script {
                    currentBuild.displayName += " ${TAG}"
                }


                withCredentials([usernamePassword(credentialsId: 'docker-hub-nimbusbuildserver', passwordVariable: 'HUB_PASS', usernameVariable: 'HUB_USER')]) {
                    sh label: "Docker Login", script: 'docker login --username "$HUB_USER" --password-stdin <<< $HUB_PASS'
                    //Push AOS (Dev)
                    sh label: "Set Docker App Version", script: "sed -i -e \"s,<version>,${TAG},g\" ${IMAGE_NAME}.dockerapp"
                    sh label: "Set Tag", script: "sed -i -e \"s,<tag>,${TAG},g\" ${IMAGE_NAME}.dockerapp"
                    sh label: "Validate Docker App File", script: "docker-app validate ${IMAGE_NAME}.dockerapp"
                    sh label: "Push Docker App File for Pushing Images",script: "docker-app push ${IMAGE_NAME}.dockerapp"
                    sh label: "Run Push", script: "nimbusapp ${IMAGE}:${TAG} render | docker-compose -f - push"
                    sh label: "Strip Build Context For Running", script: "sed -i -e '/build: ./d' ${IMAGE_NAME}.dockerapp"
                    sh label: "Validate Docker App File", script: "docker-app validate ${IMAGE_NAME}.dockerapp"
                    sh label: "Push Docker App Production File", script: "docker-app push ${IMAGE_NAME}.dockerapp"
                    sh label: "Cache Docker App via Render", script: "nimbusapp ${IMAGE}:${TAG} render"
                    sh label: "Updating permissions on update script", script: "chmod +x push/update-dockerapp-metadata.sh"
                    sh label: "Updating README for Dockerapp", script: "push/update-dockerapp-metadata.sh \$HUB_USER \$HUB_PASS \${IMAGE}.dockerapp $TAG"


                    //Push AOS (QA)
                    sh label: "Strip Build Context For QA for Running", script: "sed -i -e '/build: ./d' ${IMAGE_NAME}-qa.dockerapp"
                    sh label: "Set Docker App Version for QA", script: "sed -i -e \"s,<version>,${TAG},g\" ${IMAGE_NAME}-qa.dockerapp"
                    sh label: "Set Tag for QA", script: "sed -i -e \"s,<tag>,${TAG},g\" ${IMAGE_NAME}-qa.dockerapp"
                    sh label: "Validate Docker App File for QA", script: "docker-app validate ${IMAGE_NAME}-qa.dockerapp"
                    sh label: "Push Docker App Production File for QA", script: "docker-app push ${IMAGE_NAME}-qa.dockerapp"
                    sh label: "Cache Docker App via Render for QA", script: "nimbusapp ${IMAGE}-qa:${TAG} render"
                    sh label: "Updating README for Dockerapp for QA", script: "push/update-dockerapp-metadata.sh \$HUB_USER \$HUB_PASS \${IMAGE}-qa.dockerapp $TAG"

                }
            }
        }

        stage('Create Github Release') {
            when {
                expression { params.PUSH && !TAG.equals("latest")  }
            }
            steps {
                withCredentials([usernamePassword(credentialsId: 'nimbusbuildserver-git', passwordVariable: 'GITHUB_PASS', usernameVariable: 'GITHUB_USER')]) {
                    sh label: "Create GitHub Release", script: """
                        BRANCH=${TAG}
                        PR_URL="\$(gh pr create --title \${BRANCH} --body \${BRANCH} -B main -H \$BRANCH | tail -n 1)"
                        gh pr merge \$PR_URL -m
                        gh release create \$BRANCH -t \$BRANCH -n \$BRANCH
                        
                    """
                }
            }
        }

        stage('Notify Release') {
            when {
                expression { params.PUSH && !TAG.equals("latest") && !params.SILENTRELEASE }
            }
            steps {
                office365ConnectorSend(
                        message: "Advantage Online Shopping ${TAG} has been released - <a href=https://hub.docker.com/repository/docker/admpresales/${IMAGE_NAME}.dockerapp>Docker Hub</a>",
                        webhookUrl: "${env.MS_URL_RELEASE}"
                )
            }
        }
    }
    post {
        always {
            office365ConnectorSend(
                    color:  (currentBuild.currentResult == 'SUCCESS') ? '00FF00' : 'FF0000',
                    message: "Build ${currentBuild.displayName} *${currentBuild.currentResult}* in ${currentBuild.durationString.replaceAll(' and counting', '')}",
                    webhookUrl: "${env.MS_URL}",
                    status: "${currentBuild.currentResult}"
            )
            sh label: "Kill credential server", script: "docker rm -f ftpcred-${IMAGE_NAME} || true"
        }
    }
}
