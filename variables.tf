variable "demo_config" {
  type = object({
    hostname = optional(string, "demo")

    layers = optional(map(object({
      package_name = optional(string) # default is the layer name
      package_hash = optional(string) # default is a dummy package
      runtimes     = optional(list(string), ["python3.10"])
      })), {
      dependencies = {}
    })

    functions = map(object({
      runtime        = optional(string, "python3.10")
      handler        = optional(string, "%s.handle") # %s is placeholder for the function name
      package_name   = optional(string)              # default is the function name
      package_hash   = optional(string)              # default is a dummy package
      stable_version = optional(string)              # default is the previous version
      traffic_shift  = optional(number, 0.2)         # between 0 and 1 (inclusive)
      log_retention  = optional(number, 14)          # in days
      environment    = optional(map(string))         # environment variables
      used_layers    = optional(list(string), ["dependencies"])
    }))
  })
}
