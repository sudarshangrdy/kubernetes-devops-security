pipeline {
  agent any

  environment {
    deploymentName = "devsecops"
    containerName = "devsecops-container"
    serviceName = "devsecops-svc"
    imageName = "iamharryindoc/numeric-app:$GIT_COMMIT"
    applicationURL="http://devsecops-demo.eastus.cloudapp.azure.com/"
    applicationUTI="/increment/99"
  }

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
            //Placed at the bottom
            //post {
				    //  always {
					  //    junit 'target/surefire-reports/*.xml'
					  //    jacoco execPattern: 'target/jacoco.exec'
				    //  }
			      //}
      }

      stage('Mutation test - PIT') {
        steps {
          sh 'mvn org.pitest:pitest-maven:mutationCoverage'
        }
        //As below plugin not working properly, also placed at the bottom
        //post {
        //  always {
        //    pitmutation mutationStatsFile: '**/target/pit-reports/**/mutations.xml'
        //  }
        //}
      }

      stage('SonarQube Analysis') {
        steps {
          withSonarQubeEnv('JenSonarqube') {
            sh "mvn sonar:sonar -Dsonar.projectKey=devsecops-app"
          }
          timeout(time: 2, unit: 'MINUTES') {
            // Parameter indicates whether to set pipeline to UNSTABLE if Quality Gate fails
            // true = set pipeline to UNSTABLE, false = don't
            script {
              waitForQualityGate abortPipeline: true
            }
          }
        }
      }

      //Merging two stages using parallel
      //stage('Dependency Scan - Check') {
			//	steps {
			//		sh "mvn dependency-check:check"
			//	}
        //Placed at the bottom
				//post {
				//	always {
				//		dependencyCheckPublisher pattern: 'target/dependency-check-report.xml'
				//	}
        //    }
			//}

      stage('Dependency Scan - Trivy Check') {
				steps {
					parallel(
					  "Dependency Scan" : {
						  sh "mvn dependency-check:check"
					  },
					  "Trivy Scan": {
						  sh "bash trivy-docker-image-scan.sh"
					  },
            "OPA-Conftest": {
              sh 'docker run --rm -v $WORKSPACE:/project openpolicyagent/conftest test --policy op-security-docker.rego Dockerfile'
            }
					) 
				}
			}

      stage('Docker Build and Push') {
	      steps {//added sudo only trivy
          withDockerRegistry([credentialsId: "docker-hub", url: ""]) {
            sh 'printenv'
            sh 'sudo docker build -t iamharryindoc/numeric-app:""$GIT_COMMIT"" .'
            sh 'docker push iamharryindoc/numeric-app:""$GIT_COMMIT""'
		      }
	      }
      }

      //Added a paralle step  below
      //stage('Vulnerability Scan - Kubernetes') {
	    //  steps {
		  //    sh "docker run --rm -v $WORKSPACE:/project openpolicyagent/conftest test --policy op-security-k8s.rego //k8s_deployment_service.yaml"
	    //  }
      //}

      stage('Vulnerability Scan - Kubernetes') {
	      steps {
          parallel (
            "OPA Scan" : {
              sh "docker run --rm -v $WORKSPACE:/project openpolicyagent/conftest test --policy op-security-k8s.rego //k8s_deployment_service.yaml"
            },
            "kubesec scan": {
              sh "bash kubesec-scan.sh"
            }
          )
	      }
      }

       //Placing this stage in two stages for handling rollback 
      //stage('Kubernetes Deployment - DEV') {
	    //  steps {
		  //    withKubeConfig([credentialsId: "kubernetescrd"]) {
			//      sh "sed -i 's#replace#iamharryindoc/numeric-app:${GIT_COMMIT}#g' k8s_deployment_service.yaml"
			//      sh 'kubectl apply -f k8s_deployment_service.yaml'
		  //    }
	    //  }
      //}

       stage('K8s Deployment - DEV') {
          steps {
            withKubeConfig([credentialsId: "kubernetescrd"]) {
              sh "bash k8s-deployment.sh"
            }
          }
        }

        stage('K8s check deployment status - DEV') {
          steps {
            withKubeConfig([credentialsId: "kubernetescrd"]) {
              sh "bash k8s-deployment-rollout-status.sh"
            }
          }
        }
    }

   

    post {
        always {
          junit 'target/surefire-reports/*.xml'
					jacoco execPattern: 'target/jacoco.exec'
          //pitmutation mutationStatsFile: '**/target/pit-reports/**/mutations.xml'
          dependencyCheckPublisher pattern: 'target/dependency-check-report.xml'
        }
      }
}