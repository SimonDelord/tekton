# Introduction
This is my github repo for all Tekton related activities.\
I am going to try to integrate some of the ACM functions with Tekton and see how they can be used together.

The environment is the following:
   - one OCP cluster used as a Hub/Dev environment.
   - one OCP cluster used as a Prod environment.

ACM is being used as a way of deploying:
   - triggers and pipelines to any cluster where developers will be using them
apps in both dev and prod environments

GitHub is used as the code repo environment:
   - some repositories have been used for ACM to deploy 

The use case is the following (3 steps demo):
   - **First Step** An infra/devops person creates various Tekton Tasks, Pipelines, Trigger components (TriggerTemplates, TriggerBindings) and uploads them into a GitHub repo. All these Tekton "capabilities" are then imported to the relevant OCP clusters via ACM.
   - **Second Step - First pipeline** A developer then sends a request (either via logging into a service-portal or by starting a specific Tekton pipeline) to request an environment to deploy their app. This triggers a Tekton pipeline (called the initial-app-setup-pipeline) that:
         - Creates various Git Repos for the developer (dev and prod)
         - Creates various webhooks in the Git Repos and EventListeners on the OCP clusters
         - Subscribes ACM to the Git Repos (e.g mapping the Dev Git Repo to the Dev OCP cluster and the Prod Git Repo to the Prod OCP cluster)         
   - **Third Step - Second pipeline** The developer then uploads their app intot the Git Hub dev-repo. This triggers:
         - ACM to deploy the application onto the Dev OCP cluster
         - A Tekton pipeline (via the webhook created in step 2) that:
              - runs some test(s) on the Repo/Files (e.g the K8 YAML files describing the app)
              - based on the success for the test(s), pushes those files to the Prod Git Repo.
         - ACM then deploys the application into the Production environment once Tekton has finished uploading the files onto the Prod Git Repo. 

## PipelineRun - initial-app-setup-pipelineRun

This pipelineRun is used when a developer wants to request an environment to deploy their app.

It does the following:
   - **Task1:** create a dev-git-repo (this is where the developer will deploy and test to the dev cluster)
   - **Task2:** create a prod-git-repo (this is where the code will deployed when it passes successfully tests and it will get deployed onto the Prod environment)
   - **Task3:** create an eventListener (this eventListener will be used to trigger the second pipeline when the developer modifies code within the dev-git-repo)
   - **Task4:** create a webhook in the dev-git-repo (this webhook will notify the eventListener every time there is a change within the dev-git-repo)
   - **Task5:** links the dev-git-repo to the dev environment via ACM
   - **Task6:** links the prod-git-repo to the prod environment via ACM 



### Task1 - Create a dev-git-repo
For this task, as usual, I did it the ugly way by running a script and using the GitHub API for creating a repo.\
Some of the components that should be optimised are:\
not hardcoding the user & token as well as the name of the repo to be created.

### Task2 - Create a prod-git-repo
Same as task1, see above.

### Task3 - Create an eventListener
For this task, I rely on the openshift-client Task from the Tekton catalog (https://github.com/tektoncd/catalog/tree/master/task/openshift-client)\

The openshift-client Task can be imported manually via an oc apply -f https://... or by uploading the file to the Pipelines folder that will then rely on ACM to import it onto the right cluster.\

There is also a need for Tasks 3, 5 & 6 to use a service account that has the rights to perform those actions in the relevant namespace(s).\
I have gone with oc policy add-role-to-user cluster-admin system:serviceaccount:default:builder which is probably not the right way but i didn't really want\
to fine-tune the rights roles and access\

The eventListener is imported from a pre-defined template located in folder oc-files (e.g the folder of the files required as a parameter for running an openshift-client Task).\
The eventListener relies on a simple combination of triggerTemplate and triggerBinding that are available in the Trigger folder and available on the hub-cluster via ACM.\

### Task4 - Create a webhook in the dev-git-repo

In this task, I use something similar to tasks 1 and 2 and use the GitHub API for calling a webhook. Because of the naming structure of the eventListener (route) I simply hardcoded it in the script part of the task, but obviously this could/should be used as an input for the webhook creation.

### Tasks 5 & 6 - Link the dev-git and prod-git-repo to OCP clusters via ACM

I use a similar approach as for step 3, relying on openshift-client Task. The ACM resource files (Application, Channel, Placement-Rule and Subscription) are compiled into a single YAML file located in the folder oc-files (acm-dev-git-repo-import.yaml for the dev environment and acm-prod-git-repo-import.yaml for the prod environmnent).


### PipelineRun - Test and Copy Git Repo Pipeline

This pipelineRun is used when a developer wants to commit software to Dev / Production.

It does the following:
   - **Task1:** wait for ACM to deploy on the Dev Cluster 
   - **Task2:** Run a first test against the content in Dev-repo 
   - **Task3:** Run a second test against the content in Dev-repo
   - **Task4:** Copy files from the git Dev-repo to the git Prod-repo
 
 ### Task1 - wait for ACM to deploy on the Dev Cluster
For this task, as usual, I simply ran a Task called wait (waitTask.yaml in the Pipelines folder) that waits for 10 seconds.

 ### Tasks 2 & 3 - Run a test on the Dev Cluster
For this task, as usual, I simply ran a Task called test (testTask.yaml in the Pipelines folder) that waits for 10 seconds and returns a "test successful" message. Ideally, I'd run some real tests against either Dev cluster app that's been spun up &/or the Dev-repo to check the validity of the code. Maybe another time ;-)

### Task 4 - Copy files from the git Dev-repo to the git Prod-repo

For this task I use the git-cli (https://raw.githubusercontent.com/tektoncd/catalog/master/task/git-cli/0.1/git-cli.yaml).
Again, I did hardcode the user:password for GitHub in the git push https:// command and in a proper environment it would need to be done properly (for another time maybe). 


