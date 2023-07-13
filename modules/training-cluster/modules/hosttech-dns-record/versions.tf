terraform {
  required_providers {
    restapi = {
      source                = "Mastercard/restapi"
      configuration_aliases = [restapi.hosttech_dns]
    }
  }

}
