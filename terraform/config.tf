locals {
  // Here we're creating a simple nested map of data to act as configuration
  // for our API Gateway and Lambda functions. This is somewhat primitive due
  // to the nature of the application, and is not meant to be a complete example
  // of production Terraform. Ideally we'd be using workspaces and have versions for
  // software (packages/builds/images etc.) coming from an automated source and tightly
  // integrated with whatever CI/CD system is being used.
  //
  // However, this does allow a somewhat dynamic definition of multiple environments
  // as the top level keys within the `stages` map are used to define both the gateway
  // stages as well as the lambda aliases, and marries the two together. Again, this would
  // be better with Workspaces as it would allow distinct code changes in the Terraform
  // to be run independent, as well as tracking the state for each independently and thus
  // reducing the blast radius of misconfigurations.
  stages = {
    dev = {
      // Automatically deploy gateway changes to dev
      automatic = true

      // Always use the latest Lambda version in dev
      function_version = "$LATEST"
    }

    test = {
      // Don't automatically deploy gateway changes to test
      automatic = false

      // Use specific gateway deployment
      deployment_id = "17xwrx"

      // Use version 2 in test
      function_version = "3"
    }

    live = {
      // Don't automatically deploy gateway changes to live
      automatic = false

      // Use specific gateway deployment
      deployment_id = "17xwrx"

      // Use version 1 in live
      function_version = "2"
    }
  }
}
