edgerc_path         = ""
config_section      = ""
notification_emails = [""]
contract_id         = ""
group_id            = ""
default_origin      = ""
name                = ""
activate_to_staging = true

# IP/Geo Firewall
client_lists_ipblock  = [] 
client_lists_geoblock = [] 


#Sec config
group_name      = ""
config_name     = ""
description     = ""
inspection_size = 32

policies = {
  low_security = {
    policy_name   = ""
    policy_prefix = "" # exactly 4 uppercase alphanumeric characters, unique per policy
    hostnames     = []
  }
}


# =================================================
# POLICY DEFAULTS
# =================================================
# These values apply to ALL policies unless a policy provides its own override.
#
# HOW TO CHANGE AN ACTION:
#   Valid action values are: "none", "alert", "deny"
#   - "none"  = protection disabled for that rule
#   - "alert" = log only (monitor mode) — good for initial rollout
#   - "deny"  = actively block matching requests
#
#   To change an action, simply update the value here in policy_defaults
#   (affects all policies) or override it in a specific policy entry below.
# =================================================
policy_defaults = {
  # --- Protection Toggles ---
  # Set to true/false to enable/disable entire protection categories.
  enable_waf                 = true
  enable_request_constraints = true
  enable_ip_geo              = true
  enable_malware             = false
  enable_rate                = true
  enable_slow_post           = true
  enable_client_reputation   = true
  enable_botman              = false

  # --- DoS Protection ---
  dos_origin_error_action       = "alert"
  dos_post_page_requests_action = "alert"
  dos_page_view_requests_action = "alert"
  slow_post_action              = "alert"

  # --- WAF Actions ---
  # Controls how each WAF attack group responds when a match is detected.
  # Example: to block SQL injection across all policies, change waf_sql_action to "deny".
  waf_policy_action   = "alert"
  waf_wat_action      = "alert"
  waf_protocol_action = "alert"
  waf_sql_action      = "alert"
  waf_xss_action      = "alert"
  waf_cmd_action      = "alert"
  waf_lfi_action      = "alert"
  waf_rfi_action      = "alert"
  waf_platform_action = "alert"
  penalty_box_action  = "alert"

  # --- Client Reputation Actions ---
  rep_web_attackers_high  = "alert"
  rep_web_attackers_low   = "alert"
  rep_dos_attackers_high  = "alert"
  rep_dos_attackers_low   = "alert"
  rep_scanning_tools_high = "alert"
  rep_scanning_tools_low  = "alert"
  rep_web_scrapers_high   = "alert"
  rep_web_scrapers_low    = "alert"
  # --- Bot Manager General Settings ---
  add_akamai_bot_header     = false
  enable_active_detections  = false
  enable_browser_validation = false
  remove_botman_cookies     = true
  third_party_proxy         = true

  # --- Bot Category Actions ---
  bot_site_monitoring_and_web_development = "monitor"
  bot_academic_or_research                = "monitor"
  bot_job_search_engine                   = "monitor"
  bot_artificial_intelligence_ai          = "monitor"
  bot_online_advertising                  = "monitor"
  bot_ecommerce_search_engine             = "monitor"
  bot_web_search_engine                   = "monitor"
  bot_enterprise_data_aggregator          = "monitor"
  bot_financial_services                  = "monitor"
  bot_social_media_or_blog                = "monitor"
  bot_web_archiver                        = "monitor"
  bot_business_intelligence               = "monitor"
  bot_news_aggregator                     = "monitor"
  bot_rss_feed_reader                     = "monitor"
  bot_financial_account_aggregator        = "monitor"
  bot_media_or_entertainment_search       = "monitor"
  bot_seo_analytics_or_marketing          = "monitor"

  # --- Bot Transparent Detection Actions ---
  bot_impersonators_of_known_bots            = "monitor"
  bot_development_frameworks                 = "monitor"
  bot_http_libraries                         = "monitor"
  bot_web_services_libraries                 = "monitor"
  bot_open_source_crawlersscraping_platforms = "monitor"
  bot_headless_browsersautomation_tools      = "monitor"
  bot_declared_bots_keyword_match            = "monitor"
  bot_aggressive_web_crawlers                = "monitor"
  bot_browser_impersonator                   = "monitor"
  bot_web_scraper_reputation                 = "monitor"

  # --- Bot Active Detection Actions ---
  bot_cookie_integrity_failed                       = "monitor"
  bot_session_validation                            = "monitor"
  bot_client_disabled_javascript_noscript_triggered = "monitor"
  bot_javascript_fingerprint_anomaly                = "monitor"
  bot_javascript_fingerprint_not_received           = "monitor"
}


