pipeline {
  agent any

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
      post {
        always {
          junit 'target/surefire-reports/*.xml'
          jacoco execPattern: 'target/jacoco.exec'
        }
      }
    }
    stage ('Docker build and Push') {
      steps {
        // outdate-approach-to-call docker.withRegistry('https://hub.docker.com/', 'docker-hub'){
        withDockerRegistry([credentialsId: "docker-hub", url: ""]) {
          sh 'printenv'
        sh 'docker build -t ezzy187/numeric-app:""$GIT_COMMIT"" .'
        sh 'docker push ezzy187/numeric-app:""$GIT_COMMIT""'
        }
        
      }
    }
  }     
}
