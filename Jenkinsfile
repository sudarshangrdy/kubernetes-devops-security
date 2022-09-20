pipeline {
  agent any

  stages {
      stage('Build Artifact') {
            steps {
              sh "mvn clean package -DskipTests=true"
              archive 'target/*.jar' 
            }
      }

      stage('Test Stage') {
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

      stage('Docker Build and Push') {
	      steps {
          docker.withRegistry('', 'docker-hub') {
            def newApp = docker.build "iamharryindoc/numeric-app:${env.GIT_COMMIT}"
            newApp.push()
          }
	      }
      }  

    }
}