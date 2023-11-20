variable "demo_app_dynamic_config" {
  default = {
    hostname = "demo"

    layers = {
      for name in ["dependencies"] :
      name => {
        package_hash = ""
        runtimes     = ["python3.10"]
      }
    }

    functions = {
      for name in [
        "request_handler",
        "command_handler",
        "event_publisher",
        "event_consumer"
      ] :
      name => {
        runtime        = "python3.10"
        handler        = "${name}.handle"
        package_hash   = ""
        stable_version = ""
        traffic_shift  = 0.2
        log_retention  = 14
        environment    = {}
        used_layers    = ["dependencies"]
      }
    }
  }
}
