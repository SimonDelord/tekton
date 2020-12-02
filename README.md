# Introduction
This is my github repo for all Tekton related activities.\
I am going to try to integrate some of the ACM functions with Tekton and see how they can be used together.\

The environment is the following\

one OCP cluster used as a Hub/Dev environment.\
one OCP cluster used as a Prod environment.\

ACM is being used as a way of deploying:\
triggers and pipelines to any cluster where developers will be using them\
apps in both dev and prod environments\

GitHub is used as the code repo environment:\
some repositories have been used for ACM to deploy 

The use case is the following\
A developer logs into a service-portal to request an environment to deploy their app\
This triggers the first pipelineRun - called initial-app-setup-pipelineRun\
This pipeline does the following:\
**Task1:** create a dev-git-repo (this is where the developer will deploy and test to the dev cluster)\
**Task2:** create a prod-git-repo (this is where the code will deployed when it passes successfully tests and it will get deployed onto the Prod environment)\
**Task3:** create an eventListener (this eventListener will be used to trigger the second pipeline when the developer modifies code within the dev-git-repo)\
**Task4:** create a webhook in the dev-git-repo (this webhook will notify the eventListener every time there is a change within the dev-git-repo)\
**Task5:** links the dev-git-repo to the dev environment via ACM \
**Task6:** links the prod-git-repo to the prod environment via ACM \

## PipelineRun - initial-app-setup-pipelineRun

This pipelineRun is used when a developer wants to request an environment to deploy their app.

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


### PipelineRun - Test and Promote to Production 


