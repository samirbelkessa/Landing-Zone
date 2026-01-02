################################################################################
# M07 - Data Collection Rules
# 
# Creates Azure Monitor Data Collection Rules (DCR) for Azure Monitor Agent (AMA)
# Supports all DCR features: performance counters, event logs, syslog, IIS, custom logs
################################################################################

################################################################################
# Data Collection Rules
################################################################################

resource "azurerm_monitor_data_collection_rule" "this" {
  for_each = var.data_collection_rules
  
  name                = each.key
  location            = each.value.location
  resource_group_name = each.value.resource_group_name
  description         = try(each.value.description, "Data Collection Rule managed by Terraform M07")
  kind                = try(each.value.kind, null)
  
  #-----------------------------------------------------------------------------
  # Destinations
  #-----------------------------------------------------------------------------
  
  destinations {
    # Log Analytics Workspace(s)
    dynamic "log_analytics" {
      for_each = try(each.value.destinations.log_analytics, null) != null ? each.value.destinations.log_analytics : {}
      
      content {
        workspace_resource_id = log_analytics.value.workspace_resource_id
        name                  = try(log_analytics.value.name, log_analytics.key)
      }
    }
    
    # Azure Monitor Metrics
    dynamic "azure_monitor_metrics" {
      for_each = try(each.value.destinations.azure_monitor_metrics, null) != null ? [each.value.destinations.azure_monitor_metrics] : []
      
      content {
        name = try(azure_monitor_metrics.value.name, "azureMonitorMetrics")
      }
    }
    
    # Storage Account(s)
    dynamic "storage_blob" {
      for_each = try(each.value.destinations.storage_blob, null) != null ? each.value.destinations.storage_blob : {}
      
      content {
        storage_account_id = storage_blob.value.storage_account_id
        container_name     = storage_blob.value.container_name
        name               = try(storage_blob.value.name, storage_blob.key)
      }
    }
    
    # Event Hub(s)
    dynamic "event_hub" {
      for_each = try(each.value.destinations.event_hub, null) != null ? each.value.destinations.event_hub : {}
      
      content {
        event_hub_id = event_hub.value.event_hub_id
        name         = try(event_hub.value.name, event_hub.key)
      }
    }
    
    # Event Hub Direct
    dynamic "event_hub_direct" {
      for_each = try(each.value.destinations.event_hub_direct, null) != null ? each.value.destinations.event_hub_direct : {}
      
      content {
        event_hub_id = event_hub_direct.value.event_hub_id
        name         = try(event_hub_direct.value.name, event_hub_direct.key)
      }
    }
  }
  
  #-----------------------------------------------------------------------------
  # Data Flows
  #-----------------------------------------------------------------------------
  
  dynamic "data_flow" {
    for_each = each.value.data_flow
    
    content {
      streams       = data_flow.value.streams
      destinations  = data_flow.value.destinations
      transform_kql = try(data_flow.value.transform_kql, null)
      output_stream = try(data_flow.value.output_stream, null)
    }
  }
  
  #-----------------------------------------------------------------------------
  # Data Sources
  #-----------------------------------------------------------------------------
  
  dynamic "data_sources" {
    for_each = try(each.value.data_sources, null) != null ? [each.value.data_sources] : []
    
    content {
      # Performance Counters
      dynamic "performance_counter" {
        for_each = try(data_sources.value.performance_counter, null) != null ? data_sources.value.performance_counter : []
        
        content {
          streams                       = performance_counter.value.streams
          sampling_frequency_in_seconds = performance_counter.value.sampling_frequency_in_seconds
          counter_specifiers            = performance_counter.value.counter_specifiers
          name                          = performance_counter.value.name
        }
      }
      
      # Windows Event Logs
      dynamic "windows_event_log" {
        for_each = try(data_sources.value.windows_event_log, null) != null ? data_sources.value.windows_event_log : []
        
        content {
          streams        = windows_event_log.value.streams
          x_path_queries = windows_event_log.value.x_path_queries
          name           = windows_event_log.value.name
        }
      }
      
      # Linux Syslog
      dynamic "syslog" {
        for_each = try(data_sources.value.syslog, null) != null ? data_sources.value.syslog : []
        
        content {
          streams        = syslog.value.streams
          facility_names = syslog.value.facility_names
          log_levels     = syslog.value.log_levels
          name           = syslog.value.name
        }
      }
      
      # IIS Logs
      dynamic "iis_log" {
        for_each = try(data_sources.value.iis_log, null) != null ? data_sources.value.iis_log : []
        
        content {
          streams         = iis_log.value.streams
          log_directories = try(iis_log.value.log_directories, null)
          name            = iis_log.value.name
        }
      }
      
      # Custom Log Files
      dynamic "log_file" {
        for_each = try(data_sources.value.log_file, null) != null ? data_sources.value.log_file : []
        
        content {
          streams       = log_file.value.streams
          file_patterns = log_file.value.file_patterns
          format        = log_file.value.format
          name          = log_file.value.name
          
          dynamic "settings" {
            for_each = try(log_file.value.settings, null) != null ? [log_file.value.settings] : []
            
            content {
              dynamic "text" {
                for_each = try(settings.value.text, null) != null ? [settings.value.text] : []
                
                content {
                  record_start_timestamp_format = text.value.record_start_timestamp_format
                }
              }
            }
          }
        }
      }
      
      # Extensions (Dependency Agent, etc.)
      dynamic "extension" {
        for_each = try(data_sources.value.extension, null) != null ? data_sources.value.extension : []
        
        content {
          streams            = extension.value.streams
          extension_name     = extension.value.extension_name
          extension_json     = try(extension.value.extension_json, null)
          input_data_sources = try(extension.value.input_data_sources, null)
          name               = extension.value.name
        }
      }
      
      # Prometheus Forwarder
      dynamic "prometheus_forwarder" {
        for_each = try(data_sources.value.prometheus_forwarder, null) != null ? data_sources.value.prometheus_forwarder : []
        
        content {
          streams = prometheus_forwarder.value.streams
          name    = prometheus_forwarder.value.name
          
          dynamic "label_include_filter" {
            for_each = try(prometheus_forwarder.value.label_include_filter, null) != null ? prometheus_forwarder.value.label_include_filter : []
            
            content {
              label = label_include_filter.value.label
              value = label_include_filter.value.value
            }
          }
        }
      }
      
      # Platform Telemetry
      dynamic "platform_telemetry" {
        for_each = try(data_sources.value.platform_telemetry, null) != null ? data_sources.value.platform_telemetry : []
        
        content {
          streams = platform_telemetry.value.streams
          name    = platform_telemetry.value.name
        }
      }
    }
  }
  
  #-----------------------------------------------------------------------------
  # Identity (optional - for certain data sources)
  #-----------------------------------------------------------------------------
  
  dynamic "identity" {
    for_each = try(each.value.identity, null) != null ? [each.value.identity] : []
    
    content {
      type         = identity.value.type
      identity_ids = try(identity.value.identity_ids, null)
    }
  }
  
  #-----------------------------------------------------------------------------
  # Stream Declarations (for custom logs)
  #-----------------------------------------------------------------------------
  
  dynamic "stream_declaration" {
    for_each = try(each.value.stream_declaration, null) != null ? each.value.stream_declaration : []
    
    content {
      stream_name = stream_declaration.value.stream_name
      
      dynamic "column" {
        for_each = stream_declaration.value.column
        
        content {
          name = column.value.name
          type = column.value.type
        }
      }
    }
  }
  
  #-----------------------------------------------------------------------------
  # Tags
  #-----------------------------------------------------------------------------
  
  tags = local.dcr_tags[each.key]
  
  #-----------------------------------------------------------------------------
  # Lifecycle
  #-----------------------------------------------------------------------------
  
  lifecycle {
    create_before_destroy = true
    
    # Prevent accidental deletion of DCRs with active associations
    prevent_destroy = false
  }
}

################################################################################
# Data Collection Rule Associations (Optional)
################################################################################

resource "azurerm_monitor_data_collection_rule_association" "this" {
  for_each = var.enable_associations ? local.valid_associations : {}
  
  name                    = each.key
  target_resource_id      = each.value.target_resource_id
  data_collection_rule_id = each.value.data_collection_rule_id
  description             = each.value.description
  
  lifecycle {
    create_before_destroy = true
  }
  
  depends_on = [
    azurerm_monitor_data_collection_rule.this
  ]
}