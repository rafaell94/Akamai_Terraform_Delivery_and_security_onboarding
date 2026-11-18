resource "akamai_appsec_advanced_settings_evasive_path_match" "evasive_path_match" {
  config_id         = akamai_appsec_configuration.config.config_id
  enable_path_match = false
}

resource "akamai_appsec_advanced_settings_url_evasion_defense" "url_evasion_defense" {
  depends_on = [akamai_appsec_advanced_settings_evasive_path_match.evasive_path_match]
  config_id  = akamai_appsec_configuration.config.config_id
  status     = "enabled"
  rules = [
    {
      rule_id = 3002500
      action  = "alert"
    },
    {
      rule_id = 3002501
      action  = "alert"
    },
    {
      rule_id = 3002502
      action  = "alert"
    },
    {
      rule_id = 3002503
      action  = "alert"
    },
  ]
}

resource "akamai_appsec_advanced_settings_prefetch" "prefetch" {
  config_id            = akamai_appsec_configuration.config.config_id
  enable_app_layer     = true
  all_extensions       = false
  enable_rate_controls = false
  extensions           = ["cgi", "jsp", "aspx", "EMPTY_STRING", "php", "py", "asp"]
}

resource "akamai_appsec_advanced_settings_request_body" "config_settings" {
  config_id                     = akamai_appsec_configuration.config.config_id
  request_body_inspection_limit = var.inspection_size
}

resource "akamai_appsec_advanced_settings_pii_learning" "pii_learning" {
  config_id           = akamai_appsec_configuration.config.config_id
  enable_pii_learning = false
}

resource "akamai_appsec_advanced_settings_logging" "logging" {
  config_id = akamai_appsec_configuration.config.config_id
  logging = jsonencode(
    {
      "allowSampling" : true,
      "cookies" : {
        "type" : "all"
      },
      "customHeaders" : {
        "type" : "all"
      },
      "standardHeaders" : {
        "type" : "all"
      }
    }
  )
}

resource "akamai_appsec_siem_settings" "my_siem_settings" {
  config_id               = akamai_appsec_configuration.config.config_id
  enable_siem             = true
  enable_botman_siem       = true
  enable_for_all_policies = true
  include_ja4_fingerprint_to_siem = true
  siem_id                 = 1
}

resource "akamai_appsec_advanced_settings_attack_payload_logging" "attack_payload_logging" {
  config_id = akamai_appsec_configuration.config.config_id
  attack_payload_logging = jsonencode(
    {
      "enabled" : true,
      "requestBody" : {
        "type" : "ATTACK_PAYLOAD"
      },
      "responseBody" : {
        "type" : "ATTACK_PAYLOAD"
      }
    }
  )
}

resource "akamai_appsec_advanced_settings_pragma_header" "pragma_header" {
  config_id = akamai_appsec_configuration.config.config_id
  pragma_header = jsonencode(
    {
      "action" : "REMOVE",
      "conditionOperator" : "AND",
      "excludeCondition" : [
        {
          "type" : "requestHeaderValueMatch",
          "positiveMatch" : true,
          "header" : "aka-debug-pragma",
          "value" : [
            "Ap3y8eSAMRTDVxtW"
          ],
          "name" : "",
          "valueCase" : true,
          "valueWildcard" : false,
          "useHeaders" : false
        }
      ]
    }
  )
}

