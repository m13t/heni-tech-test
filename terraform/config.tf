locals {
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
