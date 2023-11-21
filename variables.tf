variable "demo_config" {
  type = object({
    hostname = optional(string, "demo")

    layers = map(object({
      package_hash = optional(string)
      runtimes     = optional(list(string), ["python3.10"])
    }))

    functions = map(object({
      runtime        = optional(string, "python3.10")
      handler        = optional(string, "handler.handle")
      package_name   = optional(string, "code")
      package_hash   = optional(string)
      stable_version = optional(string)
      traffic_shift  = optional(number, 0.2)
      log_retention  = optional(number, 14)
      environment    = optional(map(string))
      used_layers    = optional(list(string))
    }))
  })

  default = {
    layers = {
      dependencies = {}
    }
    functions = {
      for name in [
        "request_handler",
        "command_handler",
        "event_publisher",
        "event_consumer"
        ] : name => {
        handler     = "${name}.handle"
        used_layers = ["dependencies"]
      }
    }
  }
}
