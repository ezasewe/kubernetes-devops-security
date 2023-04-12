pipeline {
  agent any
  environment {
    deploymentName = "devsecops"
    containerName = "devsecops-container"
    serviceName = "devsecops-svc"
    imageName = "ezzy187/numeric-app:${GIT_COMMIT}"
    applicationURL="http://devsecops-demo.southafricanorth.cloudapp.azure.com"
    applicationURI="/increment/99"
  }
  triggers {
    githubPush()
  }

  stages {
      stage('Build Artifact') {
            steps {
              sh "mvn clean package -DskipTests=true"
              archive 'target/*.jar' //so that they can be downloaded later
              
            }
      }
      stage('Unit Tests - JUnit and Jacoco') {
        steps {
          sh "mvn test"
        }
      }
    stage('Mutation Tests - PIT') {
      steps {
        sh "mvn org.pitest:pitest-maven:mutationCoverage"
      }
    }
    stage('SonarQube - SAST') {
      steps {
         withSonarQubeEnv('SonarQube'){
           sh "mvn clean verify sonar:sonar \
           -Dsonar.projectKey=numeric-application \
           -Dsonar.host.url=http://devsecops-demo.southafricanorth.cloudapp.azure.com:9000 \
           -Dsonar.login=sqp_a687a423777288db48acc806e74302a2a81d2116"
         }
         timeout(time: 2, unit: 'MINUTES') {
             script {
                // Parameter indicates whether to set pipeline to UNSTABLE if Quality Gate fails
                // true = set pipeline to UNSTABLE, false = don't
                waitForQualityGate abortPipeline: true
             }
         }
      }
    }
//    stage ('Vulnerability Scan - Docker') {
//      steps {
//        sh "mvn dependency-check:check"
//      }
//    }
    stage('Vulnerability Scan - Docker') {
      steps {
        parallel(
             "Dependency Scan": {
                     sh "mvn dependency-check:check"
             },
             "Trivy Scan":{
                      sh "bash trivy-docker-image-scan.sh"
             },
             "OPA Conftest":{
                  sh 'docker run --rm -v $(pwd):/project openpolicyagent/conftest test --policy opa-docker-security.rego Dockerfile'
             }
        )
      }
    }
    stage ('Docker build and Push') {
      steps {
        // outdate-approach-to-call docker.withRegistry('https://hub.docker.com/', 'docker-hub'){
        withDockerRegistry([credentialsId: "docker-hub", url: ""]) {
          sh 'printenv'
          sh 'sudo docker build -t ezzy187/numeric-app:""$GIT_COMMIT"" .'
          sh 'docker push ezzy187/numeric-app:""$GIT_COMMIT""'
        }
      }
    }
//    stage('Vulnerability Scan - Kubernetes') {
//      steps {
//            sh 'docker run --rm -v $(pwd):/project openpolicyagent/conftest test --policy opa-k8s-security.rego k8s_deployment_service.yaml'
//      }
//    }
    stage('Vulnerability Scan - Kubernetes') {
       steps {
         parallel(
           "OPA Scan": {
             sh 'docker run --rm -v $(pwd):/project openpolicyagent/conftest test --policy opa-k8s-security.rego k8s_deployment_service.yaml'
           },
           "Kubesec Scan": {
             sh "bash kubesec-scan.sh"
           },
           "Trivy Scan": {
              sh "bash trivy-k8s-scan.sh"
           }
         )
       }
    }
//    stage('Kubernetes Deployment - DEV') {
//      steps {
//        withKubeConfig([credentialsId: 'kubeconfig']) {
//         sh "sed -i 's#replace#ezzy187/numeric-app:${GIT_COMMIT}#g' k8s_deployment_service.yaml"
//         sh "kubectl apply -f k8s_deployment_service.yaml"
//        }
//      }
//    }
    stage('K8S Deployment - DEV') {
       steps {
         parallel(
           "Deployment": {
             withKubeConfig([credentialsId: 'kubeconfig']) {
               sh "bash k8s-deployment.sh"
             }
           },
           "Rollout Status": {
             withKubeConfig([credentialsId: 'kubeconfig']) {
               sh "bash k8s-deployment-rollout-status.sh"
             }
           }
         )
       }
    }
//    stage('Integration Tests - DEV') {
//       steps {
//         script {
//           try {
//             withKubeConfig([credentialsId: 'kubeconfig']) {
//               sh "bash integration-test.sh"
//             }
//           } catch (e) {
//             withKubeConfig([credentialsId: 'kubeconfig']) {
//               sh "kubectl -n default rollout undo deploy ${deploymentName}"
//             }
//             throw e
//           }
//         }
//       }
//    }
//  }
  post {
      always {
          junit 'target/surefire-reports/*.xml'
          jacoco execPattern: 'target/jacoco.exec'
          pitmutation mutationStatsFile: '**/target/pit-reports/**/mutations.xml'
          dependencyCheckPublisher pattern: 'target/dependency-check-report.xml'
      }
  }
}
