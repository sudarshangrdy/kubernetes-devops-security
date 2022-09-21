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

      stage('Mutation test - PIT') {
        steps {
          sh 'mvn org.pitest:pitest-maven:mutationCoverage'
        }
        post {
          always {
            pitmutation mutationStatsFile: '**/target/pit-reports/**/mutations.xml'
          }
        }
      }

      stage('SonarQube Analysis') {
        steps {
          withSonarQubeEnv('JenSonarqube') {
            sh "mvn clean verify sonar:sonar -Dsonar.projectKey=devsecops-app"
          }
        }
      }

      stage("Quality Gate") {
        steps {
          timeout(time: 2, unit: 'MINUTES') {
            // Parameter indicates whether to set pipeline to UNSTABLE if Quality Gate fails
            // true = set pipeline to UNSTABLE, false = don't
            waitForQualityGate abortPipeline: true
          }
        }
      }

      stage('Docker Build and Push') {
	      steps {
          withDockerRegistry([credentialsId: "docker-hub", url: ""]) {
            sh 'printenv'
            sh 'docker build -t iamharryindoc/numeric-app:""$GIT_COMMIT"" .'
            sh 'docker push iamharryindoc/numeric-app:""$GIT_COMMIT""'
		      }
	      }
      }

      stage('Kubernetes Deployment - DEV') {
	      steps {
		      withKubeConfig([credentialsId: "kubernetescrd"]) {
			      sh "sed -i 's#replace#iamharryindoc/numeric-app:${GIT_COMMIT}#g' k8s_deployment_service.yaml"
			      sh 'kubectl apply -f k8s_deployment_service.yaml'
		      }
	      }
      }  

    }
}