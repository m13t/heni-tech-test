# Heni Tech Test

The purpose of this repo is to provide a solution to an exercise set out by Heni.

## Overview

For the purposes of the exercise, ease of readability and limited time constraints, I have opted to implement a monorepo approach. Given the Lambda function
is a simplistic 'Hello, World' exercise, I have embedded the source code within the `lambda` directory, and the Terraform code within the `terraform` directory.

The Lambda function has been written in Golang, for no other reason than the runtime was not stipulated in the brief, it's exceptionally fast, quick to start and can run on Lambda's ARM architecture with little to no extra effort, which has some cost and performance benefits.
The Lambda function itself will handle two requests, one for routes matching `/`, which returns a simple 200 response with the body as `Hello, World!`. The second route, is `/build-info` which returns a JSON response of the source control information for the repository from which the build was compiled. This is more just to see some kind of change between revisions without having to make trivial code changes for the purposes of testing.

The Terraform code is responsibile for deploying the Lambda function and making it accessible by way of an API Gateway. This seemed the simplest solution to
expose the function, whilst still implementing a common approach to serverless services. The API Gateway itself is very basic in that it provides no stage specific rate limiting or logging functionality, has no CloudFront CDN in front, or support for custom domains. Some of this is in part due to time constraints, but also the ease to fork and deploy this code without changes for things like domain names, certificates etc.
The API Gateway does however demonstrate (albeit somewhat primitively) a level of isolation between different environments - stages in API Gateway parlance - which I believe is a fundamental proeprty of well defined architecture. In this particular exercise, all stages are defined within the same default workspace, and each stages has a one-to-one mapping between API Gateway stage and Lambda Alias. The key here is to demonstrate the ability to independently change versions of Lambda functions within particular API stages. Whilst this is far from an ideal production setup, the principals of what is achieved are the main point.

This was originally built and deployed directly on my machine, and later added the GitHub Actions support in order to automate the build and deployment - a section I would have liked to have explored more giving additional time. GitHub actions was fairly new to me so soaked up a lot of time trawling documentation.
Again, much like the Terraform and Lambda code, it's a primitive implementation and is lacking in common steps like security checking (beyond what is provided out the box with GitHub, Dependabot etc.), sign-off validation, terraform policy evaluation etc. It is also setup to run when `main` branch is changed, or the workflow is kicked-off manually, and doesn't chain stages for things like automatic promotion of environments as part of a normal path-to-live process. In order to change the version a Lambda function uses for a particular stage, a code change is required and the pipeline builds, which may also trigger a build of the software. Ideally, the software and infrastructure would not be so tightly coupled, but this is somewhat down to the monorepo approach, lack decoupling certain IAC elements into separate projects, and my own lack of upfront knowledge with GitHub Actions.

The code is commented and should provide a level of insight to understand it's function in addition to this document.

## Run it Yourself

First, you'll want to clone the repository:
```
$ git clone git@github.com:m13t/heni-tech-test.git
```

Once you have the respository checked out, there are a couple of things that will need to be altered before you first deploy. Firstly, the remote state bucket has been hard coded rather than passed in via a CI/CD process. You will need to update the `bucket` property in the `terraform/terraform.tf` file to an S3 bucket in which you have access to. Alternatively you could remote the entire S3 Backend block and settle for local state storage if you're only interested in running from your own device.

The next task would be to update the `config.tf` file, and comment out lines 24-44. The reason for this is that deploying this to a new AWS account would result in no known initial API Gateway stage, or Lambda function versions upon the first run. Once the first run is completed, Terraform will provide outputs for the initial API Gateway deployment of the `dev` stage, as well as the Lambda version (likely to be `1`). Once this first deployment has been created, the lines commented out above may be reinstated, and the values set to match the deployment ID and Lambda versions. There are plenty of good ways to automate this process, but for the sake of this exercise it has been left as a manual task.

This config file also serves as the main way to interact with the Terraform codebase, creating any number of stages that are needed and controlling which versions of a function and the gateway config are used for that stage. As stated earlier, this would be much better suited to using Terraform's native Workspaces functionality, as well as decoupling some of the IAC code out into separate projects, which would allow code changes to be carried out by multiple team members independently without impacting each other.

Once the application is deployed, you will see the API Gateway in the AWS console, which the accessible endpoint for each particular stage. The currently deployed function is accessible at the following URLs:

* [Dev][1]
* [Test][2]
* [Live][3]

## Given More Time

1. No monorepo - split out the applicaiton code and infrastructure code into their own repositories. Infrastructure into multiple distinct repositories to ensure proper separation of concerns, decoupling and scalability.
2. More realistic deployment approach - I'd ideally like to have implemented canary changes to the Lambda functions using something like Step Functions or CodeDeploy rather than a complete switch out, or even explored manually alterning version weights for aliases. In addition to this, and in line with the first point, having distinct pipelines for build, promote and deploy to demonstrate a proper path-to-live with the ability to keep the code immutable and idempotent between environments, rather than having to manually update a particular version for a particular stage etc. Plenty of good tools to do this, and well established methodologies.
3. Monitoring and alerting - the exercise didn't really inspire much in the way of setting up monitoring and alerting beyond some academic alert if a function invocation failed, timed out etc. I'd have liked to have implemented a slightly more complete microservice (or serverless function) architecture that involved distinct components talking with each other, or external services, as this would have better supported something tangible to monitor and alert on, particularly if this could be coupled with automated failbacks on canary deployments. Rollback currently in this implementation is a deployment of the previous version - it works but not ideal.
4. Some testing - currently the application just outputs a hello world statement, so from a test perspective, there's not a lot there to do functionally, but I'd still liked to have had something more concrete and something a bit more complex to allow for some basic stress and performance testing would have been nice too.

[1]: https://yk33m8yhtd.execute-api.eu-west-2.amazonaws.com/dev/
[2]: https://yk33m8yhtd.execute-api.eu-west-2.amazonaws.com/test/
[3]: https://yk33m8yhtd.execute-api.eu-west-2.amazonaws.com/live/
