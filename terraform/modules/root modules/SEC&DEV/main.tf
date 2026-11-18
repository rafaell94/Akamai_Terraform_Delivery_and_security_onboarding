locals {
  # Read the CSV, strip the UTF-8 BOM so the first header name ("HostName")
  # is decoded correctly, and convert tabs to commas so tab-separated exports
  # (e.g. from Excel) also work. Expected header: HostName,Origin,cert
  domain_input = csvdecode(replace(replace(file("${path.module}/input_data.csv"), "\uFEFF", ""), "\t", ","))

  # Map keyed by hostname, ready for for_each
  domains = {
    for row in local.domain_input : row.HostName => {
      origin          = row.Origin
      cert_id         = trimspace(row.cert) == "" ? null : tonumber(trimspace(row.cert))
      security_prefix = trimspace(row.policy_prefix)
    }
  }

  # One additional origin per hostname, matched by hostname only
  additional_origins = {
    for hostname, d in local.domains : hostname => {
      origin_name         = d.origin
      forward_host_header = "REQUEST_HOST_HEADER"
      hostname_match      = [hostname]
      path_match          = null
    }
  }

  # Letter buckets used to split hostnames into 6 groups. Grouping looks at
  # the first character of the hostname with any leading "www." removed;
  # hostnames starting with a digit or symbol fall into the "h-l" group.
  hostname_group_letters = {
    "a-c" = ["a", "b", "c"]
    "d-g" = ["d", "e", "f", "g"]
    "h-l" = ["h", "i", "j", "k", "l"]
    "m-p" = ["m", "n", "o", "p"]
    "q-s" = ["q", "r", "s"]
    "t-z" = ["t", "u", "v", "w", "x", "y", "z"]
  }

  # Group assigned to each hostname
  hostname_group = {
    for hostname in keys(local.domains) : hostname => coalesce(one([
      for group, letters in local.hostname_group_letters : group
      if contains(letters, substr(trimprefix(lower(hostname), "www."), 0, 1))
    ]), "h-l")
  }

  # local.domains split into groups; empty groups are omitted
  domain_groups = {
    for group in distinct(values(local.hostname_group)) : group => {
      for hostname, d in local.domains : hostname => d
      if local.hostname_group[hostname] == group
    }
  }

  # local.additional_origins split into the same groups; empty groups are omitted
  additional_origin_groups = {
    for group in distinct(values(local.hostname_group)) : group => {
      for hostname, o in local.additional_origins : hostname => o
      if local.hostname_group[hostname] == group
    }
  }
}

module "delivery_property" {
  for_each = local.domain_groups
  source   = "../../child modules/delivery/"

  #scope
  contract_id = var.contract_id
  group_id    = var.group_id

  #property
  product_id          = var.product_id
  name                = "${var.name}_${each.key}"
  cpcode_name         = "${var.name}_${each.key}"
  version_notes       = var.version_notes
  hostnames           = each.value
  default_origin      = var.default_origin
  forward_host_header = var.forward_host_header
  additional_origins  = local.additional_origin_groups[each.key]

  # EdgeHostname
  ip_behavior = var.ip_behavior

  # Activation
  notification_emails             = var.notification_emails
  activate_to_staging             = var.activate_to_staging
  activate_to_production          = var.activate_to_production
  activation_to_staging_exists    = var.activation_to_staging_exists
  activation_to_production_exists = var.activation_to_production_exists
}



# -------------------------------------------------
# Compute config-level hostnames (union of all policies)
# -------------------------------------------------
locals {

  enable_client_reputation = anytrue([
    for key, policy in var.policies :
    policy.enable_client_reputation != null ? policy.enable_client_reputation : var.policy_defaults.enable_client_reputation
  ])
}

module "security-config" {
  depends_on = [module.delivery_property]
  source        = "../../child modules/aap-asm/security-config"
  contract_id   = trimprefix(var.contract_id, "ctr_")
  group_name    = var.group_name
  config_name   = var.config_name
  description   = var.description
  hostnames     = keys(local.domains)
  version_notes = var.version_notes

  # Advanced Settings
  inspection_size = var.inspection_size

  # Client Reputation
  enable_client_reputation = local.enable_client_reputation
}


# -------------------------------------------------
# Merge policy_defaults + per-policy overrides
# Using != null ternary (NOT coalesce — coalesce treats false/"" as empty)
# -------------------------------------------------
locals {
  # Map of security prefix => list of hostnames associated with that prefix
  policies_hostnames = {
    for prefix in distinct([for d in values(local.domains) : d.security_prefix]) : prefix => [
      for hostname, d in local.domains : hostname if d.security_prefix == prefix
    ]
  }

  resolved_policies = {
    for key, policy in var.policies : key => {
      policy_name   = policy.policy_name
      policy_prefix = policy.policy_prefix
      hostnames     = local.policies_hostnames[policy.policy_prefix]

      # Protection Toggles
      enable_waf                 = policy.enable_waf != null ? policy.enable_waf : var.policy_defaults.enable_waf
      enable_request_constraints = policy.enable_request_constraints != null ? policy.enable_request_constraints : var.policy_defaults.enable_request_constraints
      enable_ip_geo              = policy.enable_ip_geo != null ? policy.enable_ip_geo : var.policy_defaults.enable_ip_geo
      enable_malware             = policy.enable_malware != null ? policy.enable_malware : var.policy_defaults.enable_malware
      enable_rate                = policy.enable_rate != null ? policy.enable_rate : var.policy_defaults.enable_rate
      enable_slow_post           = policy.enable_slow_post != null ? policy.enable_slow_post : var.policy_defaults.enable_slow_post
      enable_client_reputation   = policy.enable_client_reputation != null ? policy.enable_client_reputation : var.policy_defaults.enable_client_reputation
      enable_botman              = policy.enable_botman != null ? policy.enable_botman : var.policy_defaults.enable_botman

      # DoS Protection
      dos_origin_error_action       = policy.dos_origin_error_action != null ? policy.dos_origin_error_action : var.policy_defaults.dos_origin_error_action
      dos_post_page_requests_action = policy.dos_post_page_requests_action != null ? policy.dos_post_page_requests_action : var.policy_defaults.dos_post_page_requests_action
      dos_page_view_requests_action = policy.dos_page_view_requests_action != null ? policy.dos_page_view_requests_action : var.policy_defaults.dos_page_view_requests_action
      slow_post_action              = policy.slow_post_action != null ? policy.slow_post_action : var.policy_defaults.slow_post_action

      # WAF Actions
      waf_policy_action   = policy.waf_policy_action != null ? policy.waf_policy_action : var.policy_defaults.waf_policy_action
      waf_wat_action      = policy.waf_wat_action != null ? policy.waf_wat_action : var.policy_defaults.waf_wat_action
      waf_protocol_action = policy.waf_protocol_action != null ? policy.waf_protocol_action : var.policy_defaults.waf_protocol_action
      waf_sql_action      = policy.waf_sql_action != null ? policy.waf_sql_action : var.policy_defaults.waf_sql_action
      waf_xss_action      = policy.waf_xss_action != null ? policy.waf_xss_action : var.policy_defaults.waf_xss_action
      waf_cmd_action      = policy.waf_cmd_action != null ? policy.waf_cmd_action : var.policy_defaults.waf_cmd_action
      waf_lfi_action      = policy.waf_lfi_action != null ? policy.waf_lfi_action : var.policy_defaults.waf_lfi_action
      waf_rfi_action      = policy.waf_rfi_action != null ? policy.waf_rfi_action : var.policy_defaults.waf_rfi_action
      waf_platform_action = policy.waf_platform_action != null ? policy.waf_platform_action : var.policy_defaults.waf_platform_action
      penalty_box_action  = policy.penalty_box_action != null ? policy.penalty_box_action : var.policy_defaults.penalty_box_action

      # Client Reputation Actions
      rep_web_attackers_high         = policy.rep_web_attackers_high != null ? policy.rep_web_attackers_high : var.policy_defaults.rep_web_attackers_high
      rep_web_attackers_low          = policy.rep_web_attackers_low != null ? policy.rep_web_attackers_low : var.policy_defaults.rep_web_attackers_low
      rep_dos_attackers_high         = policy.rep_dos_attackers_high != null ? policy.rep_dos_attackers_high : var.policy_defaults.rep_dos_attackers_high
      rep_dos_attackers_low          = policy.rep_dos_attackers_low != null ? policy.rep_dos_attackers_low : var.policy_defaults.rep_dos_attackers_low
      rep_scanning_tools_high        = policy.rep_scanning_tools_high != null ? policy.rep_scanning_tools_high : var.policy_defaults.rep_scanning_tools_high
      rep_scanning_tools_low         = policy.rep_scanning_tools_low != null ? policy.rep_scanning_tools_low : var.policy_defaults.rep_scanning_tools_low
      rep_web_scrapers_high          = policy.rep_web_scrapers_high != null ? policy.rep_web_scrapers_high : var.policy_defaults.rep_web_scrapers_high
      rep_web_scrapers_low           = policy.rep_web_scrapers_low != null ? policy.rep_web_scrapers_low : var.policy_defaults.rep_web_scrapers_low

      # Bot Manager General Settings
      botman_type               = policy.botman_type != null ? policy.botman_type : var.policy_defaults.botman_type
      add_akamai_bot_header     = policy.add_akamai_bot_header != null ? policy.add_akamai_bot_header : var.policy_defaults.add_akamai_bot_header
      enable_active_detections  = policy.enable_active_detections != null ? policy.enable_active_detections : var.policy_defaults.enable_active_detections
      enable_browser_validation = policy.enable_browser_validation != null ? policy.enable_browser_validation : var.policy_defaults.enable_browser_validation
      remove_botman_cookies     = policy.remove_botman_cookies != null ? policy.remove_botman_cookies : var.policy_defaults.remove_botman_cookies
      third_party_proxy         = policy.third_party_proxy != null ? policy.third_party_proxy : var.policy_defaults.third_party_proxy

      # Bot Category Actions
      bot_site_monitoring_and_web_development = policy.bot_site_monitoring_and_web_development != null ? policy.bot_site_monitoring_and_web_development : var.policy_defaults.bot_site_monitoring_and_web_development
      bot_academic_or_research                = policy.bot_academic_or_research != null ? policy.bot_academic_or_research : var.policy_defaults.bot_academic_or_research
      bot_job_search_engine                   = policy.bot_job_search_engine != null ? policy.bot_job_search_engine : var.policy_defaults.bot_job_search_engine
      bot_artificial_intelligence_ai          = policy.bot_artificial_intelligence_ai != null ? policy.bot_artificial_intelligence_ai : var.policy_defaults.bot_artificial_intelligence_ai
      bot_online_advertising                  = policy.bot_online_advertising != null ? policy.bot_online_advertising : var.policy_defaults.bot_online_advertising
      bot_ecommerce_search_engine             = policy.bot_ecommerce_search_engine != null ? policy.bot_ecommerce_search_engine : var.policy_defaults.bot_ecommerce_search_engine
      bot_web_search_engine                   = policy.bot_web_search_engine != null ? policy.bot_web_search_engine : var.policy_defaults.bot_web_search_engine
      bot_enterprise_data_aggregator          = policy.bot_enterprise_data_aggregator != null ? policy.bot_enterprise_data_aggregator : var.policy_defaults.bot_enterprise_data_aggregator
      bot_financial_services                  = policy.bot_financial_services != null ? policy.bot_financial_services : var.policy_defaults.bot_financial_services
      bot_social_media_or_blog                = policy.bot_social_media_or_blog != null ? policy.bot_social_media_or_blog : var.policy_defaults.bot_social_media_or_blog
      bot_web_archiver                        = policy.bot_web_archiver != null ? policy.bot_web_archiver : var.policy_defaults.bot_web_archiver
      bot_business_intelligence               = policy.bot_business_intelligence != null ? policy.bot_business_intelligence : var.policy_defaults.bot_business_intelligence
      bot_news_aggregator                     = policy.bot_news_aggregator != null ? policy.bot_news_aggregator : var.policy_defaults.bot_news_aggregator
      bot_rss_feed_reader                     = policy.bot_rss_feed_reader != null ? policy.bot_rss_feed_reader : var.policy_defaults.bot_rss_feed_reader
      bot_financial_account_aggregator        = policy.bot_financial_account_aggregator != null ? policy.bot_financial_account_aggregator : var.policy_defaults.bot_financial_account_aggregator
      bot_media_or_entertainment_search       = policy.bot_media_or_entertainment_search != null ? policy.bot_media_or_entertainment_search : var.policy_defaults.bot_media_or_entertainment_search
      bot_seo_analytics_or_marketing          = policy.bot_seo_analytics_or_marketing != null ? policy.bot_seo_analytics_or_marketing : var.policy_defaults.bot_seo_analytics_or_marketing

      # Bot Transparent Detection Actions
      bot_impersonators_of_known_bots            = policy.bot_impersonators_of_known_bots != null ? policy.bot_impersonators_of_known_bots : var.policy_defaults.bot_impersonators_of_known_bots
      bot_development_frameworks                 = policy.bot_development_frameworks != null ? policy.bot_development_frameworks : var.policy_defaults.bot_development_frameworks
      bot_http_libraries                         = policy.bot_http_libraries != null ? policy.bot_http_libraries : var.policy_defaults.bot_http_libraries
      bot_web_services_libraries                 = policy.bot_web_services_libraries != null ? policy.bot_web_services_libraries : var.policy_defaults.bot_web_services_libraries
      bot_open_source_crawlersscraping_platforms = policy.bot_open_source_crawlersscraping_platforms != null ? policy.bot_open_source_crawlersscraping_platforms : var.policy_defaults.bot_open_source_crawlersscraping_platforms
      bot_headless_browsersautomation_tools      = policy.bot_headless_browsersautomation_tools != null ? policy.bot_headless_browsersautomation_tools : var.policy_defaults.bot_headless_browsersautomation_tools
      bot_declared_bots_keyword_match            = policy.bot_declared_bots_keyword_match != null ? policy.bot_declared_bots_keyword_match : var.policy_defaults.bot_declared_bots_keyword_match
      bot_aggressive_web_crawlers                = policy.bot_aggressive_web_crawlers != null ? policy.bot_aggressive_web_crawlers : var.policy_defaults.bot_aggressive_web_crawlers
      bot_browser_impersonator                   = policy.bot_browser_impersonator != null ? policy.bot_browser_impersonator : var.policy_defaults.bot_browser_impersonator
      bot_web_scraper_reputation                 = policy.bot_web_scraper_reputation != null ? policy.bot_web_scraper_reputation : var.policy_defaults.bot_web_scraper_reputation

      # Bot Active Detection Actions
      bot_cookie_integrity_failed                       = policy.bot_cookie_integrity_failed != null ? policy.bot_cookie_integrity_failed : var.policy_defaults.bot_cookie_integrity_failed
      bot_session_validation                            = policy.bot_session_validation != null ? policy.bot_session_validation : var.policy_defaults.bot_session_validation
      bot_client_disabled_javascript_noscript_triggered = policy.bot_client_disabled_javascript_noscript_triggered != null ? policy.bot_client_disabled_javascript_noscript_triggered : var.policy_defaults.bot_client_disabled_javascript_noscript_triggered
      bot_javascript_fingerprint_anomaly                = policy.bot_javascript_fingerprint_anomaly != null ? policy.bot_javascript_fingerprint_anomaly : var.policy_defaults.bot_javascript_fingerprint_anomaly
      bot_javascript_fingerprint_not_received           = policy.bot_javascript_fingerprint_not_received != null ? policy.bot_javascript_fingerprint_not_received : var.policy_defaults.bot_javascript_fingerprint_not_received
    }
  }
}

# -------------------------------------------------
# Security Policies (iterable — called with for_each)
# -------------------------------------------------
module "security-policy" {
  for_each = local.resolved_policies
  source   = "../../child modules/aap-asm/security-policy"

  config_id     = module.security-config.config_id
  policy_name   = each.value.policy_name
  policy_prefix = each.value.policy_prefix
  hostnames     = each.value.hostnames

  match_target_sequence = index(keys(local.resolved_policies), each.key)

  # Protection Toggles
  enable_waf                 = each.value.enable_waf
  enable_request_constraints = each.value.enable_request_constraints
  enable_ip_geo              = each.value.enable_ip_geo
  enable_malware             = each.value.enable_malware
  enable_rate                = each.value.enable_rate
  enable_slow_post           = each.value.enable_slow_post
  enable_client_reputation   = each.value.enable_client_reputation
  enable_botman              = each.value.enable_botman

  # IP/Geo Firewall
  client_lists_ipblock           = var.client_lists_ipblock
  client_lists_geoblock          = var.client_lists_geoblock
  client_lists_asnblock          = var.client_lists_asnblock
  client_lists_exception_ipblock = var.client_lists_exception_ipblock

  # Rate Policy Actions
  rate_policy_origin_error_id       = module.security-config.rate_policy_origin_error_id
  rate_policy_post_page_requests_id = module.security-config.rate_policy_post_page_requests_id
  rate_policy_page_view_requests_id = module.security-config.rate_policy_page_view_requests_id

  # DoS Protection
  dos_origin_error_action       = each.value.dos_origin_error_action
  dos_post_page_requests_action = each.value.dos_post_page_requests_action
  dos_page_view_requests_action = each.value.dos_page_view_requests_action
  slow_post_action              = each.value.slow_post_action

  # WAF Actions
  waf_policy_action   = each.value.waf_policy_action
  waf_wat_action      = each.value.waf_wat_action
  waf_protocol_action = each.value.waf_protocol_action
  waf_sql_action      = each.value.waf_sql_action
  waf_xss_action      = each.value.waf_xss_action
  waf_cmd_action      = each.value.waf_cmd_action
  waf_lfi_action      = each.value.waf_lfi_action
  waf_rfi_action      = each.value.waf_rfi_action
  waf_platform_action = each.value.waf_platform_action
  penalty_box_action  = each.value.penalty_box_action

  # Client Reputation
  reputation_profile_ids         = module.security-config.reputation_profile_ids
  rep_web_attackers_high         = each.value.rep_web_attackers_high
  rep_web_attackers_low          = each.value.rep_web_attackers_low
  rep_dos_attackers_high         = each.value.rep_dos_attackers_high
  rep_dos_attackers_low          = each.value.rep_dos_attackers_low
  rep_scanning_tools_high        = each.value.rep_scanning_tools_high
  rep_scanning_tools_low         = each.value.rep_scanning_tools_low
  rep_web_scrapers_high          = each.value.rep_web_scrapers_high
  rep_web_scrapers_low           = each.value.rep_web_scrapers_low

  # Bot Manager General Settings
  add_akamai_bot_header     = each.value.add_akamai_bot_header
  enable_active_detections  = each.value.enable_active_detections
  enable_browser_validation = each.value.enable_browser_validation
  remove_botman_cookies     = each.value.remove_botman_cookies
  third_party_proxy         = each.value.third_party_proxy

  # Bot Category Actions
  bot_site_monitoring_and_web_development = each.value.bot_site_monitoring_and_web_development
  bot_academic_or_research                = each.value.bot_academic_or_research
  bot_job_search_engine                   = each.value.bot_job_search_engine
  bot_artificial_intelligence_ai          = each.value.bot_artificial_intelligence_ai
  bot_online_advertising                  = each.value.bot_online_advertising
  bot_ecommerce_search_engine             = each.value.bot_ecommerce_search_engine
  bot_web_search_engine                   = each.value.bot_web_search_engine
  bot_enterprise_data_aggregator          = each.value.bot_enterprise_data_aggregator
  bot_financial_services                  = each.value.bot_financial_services
  bot_social_media_or_blog                = each.value.bot_social_media_or_blog
  bot_web_archiver                        = each.value.bot_web_archiver
  bot_business_intelligence               = each.value.bot_business_intelligence
  bot_news_aggregator                     = each.value.bot_news_aggregator
  bot_rss_feed_reader                     = each.value.bot_rss_feed_reader
  bot_financial_account_aggregator        = each.value.bot_financial_account_aggregator
  bot_media_or_entertainment_search       = each.value.bot_media_or_entertainment_search
  bot_seo_analytics_or_marketing          = each.value.bot_seo_analytics_or_marketing

  # Bot Transparent Detection Actions
  bot_impersonators_of_known_bots            = each.value.bot_impersonators_of_known_bots
  bot_development_frameworks                 = each.value.bot_development_frameworks
  bot_http_libraries                         = each.value.bot_http_libraries
  bot_web_services_libraries                 = each.value.bot_web_services_libraries
  bot_open_source_crawlersscraping_platforms = each.value.bot_open_source_crawlersscraping_platforms
  bot_headless_browsersautomation_tools      = each.value.bot_headless_browsersautomation_tools
  bot_declared_bots_keyword_match            = each.value.bot_declared_bots_keyword_match
  bot_aggressive_web_crawlers                = each.value.bot_aggressive_web_crawlers
  bot_browser_impersonator                   = each.value.bot_browser_impersonator
  bot_web_scraper_reputation                 = each.value.bot_web_scraper_reputation

  # Bot Active Detection Actions
  bot_cookie_integrity_failed                       = each.value.bot_cookie_integrity_failed
  bot_session_validation                            = each.value.bot_session_validation
  bot_client_disabled_javascript_noscript_triggered = each.value.bot_client_disabled_javascript_noscript_triggered
  bot_javascript_fingerprint_anomaly                = each.value.bot_javascript_fingerprint_anomaly
  bot_javascript_fingerprint_not_received           = each.value.bot_javascript_fingerprint_not_received

  depends_on = [module.security-config]
}


module "security_activation_staging" {
  count = var.activate_to_staging ? 1 : 0
  source = "../../child modules/aap-asm/activate-security"

  config_name = var.config_name
  config_id = module.security-config.config_id
  activation_notes = var.activation_notes
  notification_emails = var.notification_emails
  activate_to_staging = var.activate_to_staging
}