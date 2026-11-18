# -------------------------------------------------
# Common Variables
# -------------------------------------------------
variable "edgerc_path" {
  description = "Path to the .edgerc file for authentication"
  type        = string
}

variable "config_section" {
  description = "Config section in the .edgerc file for authentication."
  type        = string
}

variable "group_name" {
  description = "Akamai Group Name"
  type        = string
}


variable "config_name" {
  description = "Security configuration name"
  type        = string
}

variable "description" {
  description = "Security configuration description"
  type        = string
}


## ----------------------------------------------------------------------------
## Scope
## ----------------------------------------------------------------------------

variable "contract_id" {
  description = "Contract ID for property/config creation"
  type        = string
}

variable "group_id" {
  description = "Group ID for property/config creation."
  type        = string
}

## ----------------------------------------------------------------------------
## Property
## ----------------------------------------------------------------------------

variable "product_id" {
  description = "Property Manager product. [ION - Fresca]"
  type        = string
  default     = "Fresca"
}

variable "name" {
  description = "Property name."
  type        = string
}

variable "version_notes" {
  description = "Property version notes."
  type        = string
  default     = "Initial Config"
}

variable "default_origin" {
  description = "Default origin server for all properties"
  type        = string
}

variable "forward_host_header" {
  description = "Host header to be forwarded to the origin server. Possible fixed values are ORIGIN_HOSTNAME or REQUEST_HOST_HEADER. But the user can also select any host header they would like to use as a custom value."
  type        = string
  default     = "REQUEST_HOST_HEADER"
}

variable "additional_origins" {
  description = "Additional origins for the property. For now the match is only by hostname. The field forward_host_header allows specifying a custom host header for each additional origin.Possible fixed values are ORIGIN_HOSTNAME or REQUEST_HOST_HEADER. But the user can also select any host header they would like to use as a custom value."
  type = map(object({
    origin_name         = string
    forward_host_header = string
    hostname_match      = list(string)
    path_match          = list(string)
  }))
  default = {}
}

variable "sure_route_test_object" {
  description = "Test object path for SureRoute"
  type        = string
  default     = "/akamai/sureroute-test-object.html"
}

## ----------------------------------------------------------------------------
## Activation
## ----------------------------------------------------------------------------

variable "notification_emails" {
  description = "List or emails for notifications"
  type        = list(string)
  validation {
    condition     = length(var.notification_emails) > 0
    error_message = "At least one email should be provided"
  }
}

variable "activate_to_staging" {
  description = "Set to true to directly activate on the staging network."
  type        = bool
  default     = false
}

variable "activate_to_production" {
  description = "Set to true to directly activate on the production network."
  type        = bool
  default     = false
}

variable "noncompliance_reason" {
  type        = list(string)
  description = "Allowed values for noncompliance_reason are \"NO_PRODUCTION_TRAFFIC\", \"EMERGENCY\", \"NONE\". (OR null for the customer, as None will require the complaince block)"
  default     = []
  validation {
    condition = (
      (
        !var.activate_to_production ||
        (
          (
            length(var.noncompliance_reason) == 1 &&
            var.activate_to_production
          ) &&
          (
            contains(var.noncompliance_reason, "EMERGENCY") ||
            contains(var.noncompliance_reason, "OTHER") ||
            contains(var.noncompliance_reason, "NO_PRODUCTION_TRAFFIC") ||
            contains(var.noncompliance_reason, "NONE")
          )
        )
      )
    )
    error_message = "Allowed values for noncompliance_reason are \"NO_PRODUCTION_TRAFFIC\", \"EMERGENCY\", \"NONE\", \"OTHER\"."
  }
}

variable "ticket_id" {
  type        = string
  description = "Identifies the ticket that describes the need for the activation"
  default     = null
  validation {
    condition = (
      !var.activate_to_production ||
      (
        var.ticket_id != null &&
        var.activate_to_production
      )
    )
    error_message = " a ticket id should be logged for complaince reasons"
  }
}

variable "other_noncompliance_reason" {
  type        = string
  description = "Describes the reason why the activation must occur immediately, out of compliance with the standard procedure"
  default     = null
  validation {
    condition = (
      !var.activate_to_production ||
      !contains(var.noncompliance_reason, "OTHER") ||
      (
        var.other_noncompliance_reason != null &&
        var.activate_to_production &&
        contains(var.noncompliance_reason, "OTHER")
      )
    )
    error_message = "The other reason explanantion needs to be logged"
  }
}

variable "peer_reviewed_by" {
  type        = string
  description = "Email address of the peer who performed the review"
  default     = null
  validation {
    condition = (
      !var.activate_to_production ||
      !contains(var.noncompliance_reason, "NONE") ||
      (
        var.peer_reviewed_by != null &&
        var.activate_to_production &&
        contains(var.noncompliance_reason, "NONE")
      )
    )
    error_message = "When NONE is choosen as the non compliance reason the peer_reviewed_by field is required"
  }
}

variable "customer_email" {
  type        = string
  description = "Email address of the customer that acknowledged, tested and accepted the change"
  default     = null
  validation {
    condition = (
      !var.activate_to_production ||
      !contains(var.noncompliance_reason, "NONE") ||
      (
        var.customer_email != null &&
        var.activate_to_production &&
        contains(var.noncompliance_reason, "NONE")
      )
    )
    error_message = "When NONE is choosen as the non compliance reason the customer_email field is required"
  }
}

variable "unit_tested" {
  type        = bool
  description = "Whether the metadata to activate has been fully tested"
  default     = null
  validation {
    condition = (
      !var.activate_to_production ||
      !contains(var.noncompliance_reason, "NONE") ||
      (
        var.unit_tested != null &&
        var.activate_to_production &&
        contains(var.noncompliance_reason, "NONE")
      )
    )
    error_message = "When NONE is choosen as the non compliance reason the unit_tested field is required"
  }
}

variable "activation_notes" {
  description = "Activation notes. Leave default value until DXE-2373 is resolved, unless you know what you are doing."
  type        = string
  default     = "activated with terraform"
}


variable "activation_to_staging_exists" {
  description = "Do not modify. Flag used together with the logic in the activation resources for the initial activation to staging."
  type        = bool
  default     = false
}
variable "activation_to_production_exists" {
  description = "Do not modify. Flag used together with the logic in the activation resources for the initial activation to production."
  type        = bool
  default     = false
}



## ----------------------------------------------------------------------------
## CP Code
## ----------------------------------------------------------------------------

variable "cpcode_name" {
  description = "Default CP Code name. Will be the property name (var.name) if null."
  type        = string
  default     = null
}

## ----------------------------------------------------------------------------
## Certificate
## ----------------------------------------------------------------------------

variable "certificate_id" {
  description = <<-EOD
    Certificate enrollment id. Only applicable if enhanced_tls is true, and secure_by_default
    is false.

    Can be retrieved using AkamaiPowershell or the Akamai CPS CLI.
  EOD
  type        = number
  default     = null
}

## ----------------------------------------------------------------------------
## EdgeHostname
## ----------------------------------------------------------------------------



variable "ip_behavior" {
  description = <<-EOD
    EdgeHostname IP behaviour.
  EOD
  type        = string
  default     = "IPV4"

  validation {
    condition     = length(regexall("^(IPV4|IPV6_COMPLIANCE)$", var.ip_behavior)) > 0
    error_message = "ERROR: Valid types are IPV4 or IPV6_COMPLIANCE."
  }
}


# IP/Geo Firewall

variable "client_lists_ipblock" {
  description = "List of IP network list IDs to block"
  type        = list(string)
  default     = []
}

variable "client_lists_geoblock" {
  description = "List of geo network list IDs to block"
  type        = list(string)
  default     = []
}

variable "client_lists_asnblock" {
  description = "List of ASN network list IDs to block"
  type        = list(string)
  default     = []
}

variable "client_lists_exception_ipblock" {
  description = "List of IP network list IDs to exempt from blocking"
  type        = list(string)
  default     = []
}


# -------------------------------------------------
# Policy Defaults
# -------------------------------------------------
variable "policy_defaults" {
  description = "Default values for all security policies. Each policy inherits these unless it provides its own override."
  type = object({
    # Protection Toggles
    enable_waf                 = bool
    enable_request_constraints = bool
    enable_ip_geo              = bool
    enable_malware             = bool
    enable_rate                = bool
    enable_slow_post           = bool
    enable_client_reputation   = bool
    enable_botman              = bool

    # DoS Protection
    dos_origin_error_action       = string
    dos_post_page_requests_action = string
    dos_page_view_requests_action = string
    slow_post_action              = string

    # WAF Actions
    waf_policy_action   = string
    waf_wat_action      = string
    waf_protocol_action = string
    waf_sql_action      = string
    waf_xss_action      = string
    waf_cmd_action      = string
    waf_lfi_action      = string
    waf_rfi_action      = string
    waf_platform_action = string
    penalty_box_action  = string

    # Client Reputation Actions
    rep_web_attackers_high  = optional(string, "alert")
    rep_web_attackers_low   = optional(string, "none")
    rep_dos_attackers_high  = optional(string, "alert")
    rep_dos_attackers_low   = optional(string, "none")
    rep_scanning_tools_high = optional(string, "alert")
    rep_scanning_tools_low  = optional(string, "none")
    rep_web_scrapers_high   = optional(string, "alert")
    rep_web_scrapers_low    = optional(string, "none")

    # Bot Manager General Settings
    botman_type               = optional(string, "bvm")
    add_akamai_bot_header     = optional(bool, false)
    enable_active_detections  = optional(bool, false)
    enable_browser_validation = optional(bool, false)
    remove_botman_cookies     = optional(bool, true)
    third_party_proxy         = optional(bool, false)

    # Bot Category Actions
    bot_site_monitoring_and_web_development = optional(string, "alert")
    bot_academic_or_research                = optional(string, "alert")
    bot_job_search_engine                   = optional(string, "alert")
    bot_artificial_intelligence_ai          = optional(string, "alert")
    bot_online_advertising                  = optional(string, "alert")
    bot_ecommerce_search_engine             = optional(string, "alert")
    bot_web_search_engine                   = optional(string, "alert")
    bot_enterprise_data_aggregator          = optional(string, "alert")
    bot_financial_services                  = optional(string, "alert")
    bot_social_media_or_blog                = optional(string, "alert")
    bot_web_archiver                        = optional(string, "alert")
    bot_business_intelligence               = optional(string, "alert")
    bot_news_aggregator                     = optional(string, "alert")
    bot_rss_feed_reader                     = optional(string, "alert")
    bot_financial_account_aggregator        = optional(string, "alert")
    bot_media_or_entertainment_search       = optional(string, "alert")
    bot_seo_analytics_or_marketing          = optional(string, "alert")

    # Bot Transparent Detection Actions
    bot_impersonators_of_known_bots            = optional(string, "alert")
    bot_development_frameworks                 = optional(string, "alert")
    bot_http_libraries                         = optional(string, "alert")
    bot_web_services_libraries                 = optional(string, "alert")
    bot_open_source_crawlersscraping_platforms = optional(string, "alert")
    bot_headless_browsersautomation_tools      = optional(string, "alert")
    bot_declared_bots_keyword_match            = optional(string, "alert")
    bot_aggressive_web_crawlers                = optional(string, "alert")
    bot_browser_impersonator                   = optional(string, "alert")
    bot_web_scraper_reputation                 = optional(string, "alert")

    # Bot Active Detection Actions
    bot_cookie_integrity_failed                       = optional(string, "alert")
    bot_session_validation                            = optional(string, "alert")
    bot_client_disabled_javascript_noscript_triggered = optional(string, "alert")
    bot_javascript_fingerprint_anomaly                = optional(string, "alert")
    bot_javascript_fingerprint_not_received           = optional(string, "alert")
  })
}

# -------------------------------------------------
# Policies
# -------------------------------------------------
variable "policies" {
  description = "Map of security policies to create. Each key is a stable identifier (renaming destroys/recreates). Required per entry: policy_name, policy_prefix, hostnames. All other fields are optional and override policy_defaults when set."
  type = map(object({
    # Required
    policy_name   = string
    policy_prefix = string
    hostnames     = list(string)

    # Protection Toggles (optional overrides)
    enable_waf                 = optional(bool)
    enable_request_constraints = optional(bool)
    enable_ip_geo              = optional(bool)
    enable_malware             = optional(bool)
    enable_rate                = optional(bool)
    enable_slow_post           = optional(bool)
    enable_client_reputation   = optional(bool)
    enable_botman              = optional(bool)

    # DoS Protection
    dos_origin_error_action       = optional(string)
    dos_post_page_requests_action = optional(string)
    dos_page_view_requests_action = optional(string)
    slow_post_action              = optional(string)

    # WAF Actions
    waf_policy_action   = optional(string)
    waf_wat_action      = optional(string)
    waf_protocol_action = optional(string)
    waf_sql_action      = optional(string)
    waf_xss_action      = optional(string)
    waf_cmd_action      = optional(string)
    waf_lfi_action      = optional(string)
    waf_rfi_action      = optional(string)
    waf_platform_action = optional(string)
    penalty_box_action  = optional(string)

    # Client Reputation Actions
    rep_web_attackers_high         = optional(string)
    rep_web_attackers_high_shared  = optional(string)
    rep_web_attackers_low          = optional(string)
    rep_web_attackers_low_shared   = optional(string)
    rep_dos_attackers_high         = optional(string)
    rep_dos_attackers_high_shared  = optional(string)
    rep_dos_attackers_low          = optional(string)
    rep_dos_attackers_low_shared   = optional(string)
    rep_scanning_tools_high        = optional(string)
    rep_scanning_tools_high_shared = optional(string)
    rep_scanning_tools_low         = optional(string)
    rep_scanning_tools_low_shared  = optional(string)
    rep_web_scrapers_high          = optional(string)
    rep_web_scrapers_high_shared   = optional(string)
    rep_web_scrapers_low           = optional(string)
    rep_web_scrapers_low_shared    = optional(string)

    # Bot Manager General Settings
    botman_type               = optional(string)
    add_akamai_bot_header     = optional(bool)
    enable_active_detections  = optional(bool)
    enable_browser_validation = optional(bool)
    remove_botman_cookies     = optional(bool)
    third_party_proxy         = optional(bool)

    # Bot Category Actions
    bot_site_monitoring_and_web_development = optional(string)
    bot_academic_or_research                = optional(string)
    bot_job_search_engine                   = optional(string)
    bot_artificial_intelligence_ai          = optional(string)
    bot_online_advertising                  = optional(string)
    bot_ecommerce_search_engine             = optional(string)
    bot_web_search_engine                   = optional(string)
    bot_enterprise_data_aggregator          = optional(string)
    bot_financial_services                  = optional(string)
    bot_social_media_or_blog                = optional(string)
    bot_web_archiver                        = optional(string)
    bot_business_intelligence               = optional(string)
    bot_news_aggregator                     = optional(string)
    bot_rss_feed_reader                     = optional(string)
    bot_financial_account_aggregator        = optional(string)
    bot_media_or_entertainment_search       = optional(string)
    bot_seo_analytics_or_marketing          = optional(string)

    # Bot Transparent Detection Actions
    bot_impersonators_of_known_bots            = optional(string)
    bot_development_frameworks                 = optional(string)
    bot_http_libraries                         = optional(string)
    bot_web_services_libraries                 = optional(string)
    bot_open_source_crawlersscraping_platforms = optional(string)
    bot_headless_browsersautomation_tools      = optional(string)
    bot_declared_bots_keyword_match            = optional(string)
    bot_aggressive_web_crawlers                = optional(string)
    bot_browser_impersonator                   = optional(string)
    bot_web_scraper_reputation                 = optional(string)

    # Bot Active Detection Actions
    bot_cookie_integrity_failed                       = optional(string)
    bot_session_validation                            = optional(string)
    bot_client_disabled_javascript_noscript_triggered = optional(string)
    bot_javascript_fingerprint_anomaly                = optional(string)
    bot_javascript_fingerprint_not_received           = optional(string)
  }))

  validation {
    condition     = length(var.policies) > 0
    error_message = "At least one policy must be defined."
  }
}

# -------------------------------------------------
# Advanced settings
# -------------------------------------------------
variable "inspection_size" {
  description = "Request body inspection limit"
  type        = number
}

