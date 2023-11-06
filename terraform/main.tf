# AWS instance for Splunk
resource "aws_instance" "splunk_instance" {
  ami           = "ami-08bc783f23908136e"
  instance_type = "c5.large"

  tags = {
    Name = "SplunkInstance"
  }

  key_name               = "Splunk-test"
  vpc_security_group_ids = [aws_security_group.splunk_custom_sg.id]
}

# security group for Splunk instance
resource "aws_security_group" "splunk_custom_sg" {
  name        = "splunk_custom_sg"
  description = "Custom Security Group for Splunk"

  # Ingress rule allowing SSH access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Ingress rule allowing access to the Splunk web interface
  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Ingress rule allowing access to the Splunk port
  ingress {
    from_port   = 8089
    to_port     = 8089
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Egress rule allowing all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create a new user in Splunk with admin role
resource "splunk_authentication_users" "new_user" {
  name          = "testuser"
  password      = "testuser1"
  email         = "user_email@example.com"
  roles         = ["admin"]
}

# Create a new index in Splunk
resource "splunk_indexes" "user-test-index" {
  name                   = "user-test-index"
  max_hot_buckets        = 6
  max_total_data_size_mb = 1000000
}

# HTTP Event Collector in Splunk config
resource "splunk_global_http_event_collector" "http" {
  disabled   = false
  enable_ssl = true
  port       = 8088
}

# HTTP Event Collector token in Splunk
resource "splunk_inputs_http_event_collector" "hec-token-01" {
  name       = "hec-token-01"
  index      = "user-test-index"
  indexes    = ["user-test-index", "history", "summary"]
  source     = "aws:source"
  sourcetype = "aws:sourcetype"
  disabled   = false
  use_ack    = 0
  acl {
    owner   = "testuser"
    sharing = "global"
    read    = ["admin"]
    write   = ["admin"]
  }
  depends_on = [
    splunk_indexes.user-test-index,
    splunk_authentication_users.new_user,
  ]
}

# Create a saved search in Splunk for email alerts
resource "splunk_saved_searches" "new-search-01" {
  actions                   = "email"
  action_email_format       = "table"
  action_email_max_time     = "5m"
  action_email_send_results = false
  action_email_subject      = "Splunk Alert: $name$"
  action_email_to           = "user_email@example.com"
  action_email_track_alert  = true
  description               = "New search for user test index"
  dispatch_earliest_time    = "rt-15m"
  dispatch_latest_time      = "rt-0m"
  cron_schedule             = "*/15 * * * *"
  name                      = "new-search-01"
  search                    = "index=user-test-index source=aws:hec-token-01"

  acl {
    app     = "search"
    owner   = "testuser"
    sharing = "user"
  }
  depends_on = [
    splunk_authentication_users.new_user,
    splunk_indexes.user-test-index
  ]
}

# Create a saved search in Splunk for prices statistics
resource "splunk_saved_searches" "prices_statistics_search" {
  name                      = "Prices Statistics Search"
  search                    = "| inputlookup prices | stats avg(price) as AveragePrice, min(price) as MinPrice, max(price) as MaxPrice"
  cron_schedule             = "0 */2 * * *" # Runs every 2 hours
  description               = "Calculate statistics on product prices"
  dispatch_earliest_time    = "-24h@h"
  dispatch_latest_time      = "now"
  acl {
    app     = "search"
    owner   = "admin"
    sharing = "user"
  }
  depends_on = [
    splunk_authentication_users.new_user,
  ]
}

# Dashboard for Prices lookup visuals
resource "splunk_data_ui_views" "dashboard" {
  name     = "Terraform_Sample_Dashboard_Prices"
  eai_data = <<EAI_DATA
<dashboard>
  <row>
    <panel>
      <title>Product Prices Table</title>
      <table>
        <search>
          <query>| inputlookup prices | table productId, product_name, price, sale_price, Code</query>
          <earliest>-24h@h</earliest>
          <latest>now</latest>
        </search>
      </table>
    </panel>
  </row>
  <row>
    <panel>
      <title>Price vs Sale Price</title>
      <chart>
        <search>
          <query>| inputlookup prices | eval Difference=price-sale_price | chart avg(Difference) over product_name</query>
          <earliest>-24h@h</earliest>
          <latest>now</latest>
        </search>
        <option name="charting.chart">bar</option>
      </chart>
    </panel>
  </row>
  <row>
    <panel>
      <title>Price Distribution</title>
      <chart>
        <search>
          <query>| inputlookup prices | bin price span=10 | stats count by price</query>
          <earliest>-24h@h</earliest>
          <latest>now</latest>
        </search>
        <option name="charting.chart">column</option>
      </chart>
    </panel>
  </row>
</dashboard>
EAI_DATA

  acl {
    owner = "admin"
    app   = "search"
  }
}

#Dashboard for tutorial data
resource "splunk_data_ui_views" "dashboard_tutorialdata" {
  name     = "TutorialData_Dashboard"
  eai_data = <<EAI_DATA
<dashboard>
  <label>Tutorial Data Analysis</label>
  
  <!-- Panel for Unique Users with Failed Attempts -->
  <row>
    <panel>
      <title>Unique Users with Failed Attempts - mailsv</title>
      <table>
        <search>
          <query>index="user-test-index" source="tutorialdata.zip:./mailsv/secure.log" "Failed password" | rex "for invalid user (?&lt;User&gt;\w+)" | stats count by User</query>
          <earliest>0</earliest>
          <latest>now</latest>
        </search>
      </table>
    </panel>
  </row>
  
  <!-- Panel for Failed vs. Successful Attempts -->
  <row>
    <panel>
      <title>Failed vs. Successful Attempts - mailsv</title>
      <chart>
        <search>
          <query>index="user-test-index" source="tutorialdata.zip:./mailsv/secure.log" | eval status=case(searchmatch("Failed password"), "Failed", searchmatch("session opened"), "Successful") | stats count by status</query>
          <earliest>0</earliest>
          <latest>now</latest>
        </search>
        <option name="charting.chart">bar</option>
      </chart>
    </panel>
  </row>
  
  <!-- Panels for Top Requested Products in www1 -->
  <row>
    <panel>
      <title>Top Requested Products - www1</title>
      <chart>
        <search>
          <query>index="user-test-index" source="tutorialdata.zip:./www1/access.log" | rex field=_raw "productId=(?&lt;productId&gt;\w+)" | stats count by productId | sort - count</query>
          <earliest>0</earliest>
          <latest>now</latest>
        </search>
        <option name="charting.chart">bar</option>
      </chart>
    </panel>
  </row>
  
  <!-- Panels for Volume of Traffic Over Time for www2 -->
  <row>
    <panel>
      <title>Volume of Traffic Over Time - www2</title>
      <chart>
        <search>
          <query>index="user-test-index" source="tutorialdata.zip:./www2/access.log" | timechart span=1m count</query>
          <earliest>0</earliest>
          <latest>now</latest>
        </search>
        <option name="charting.chart">line</option>
      </chart>
    </panel>
  </row>

 <!-- Panel for Failed vs. Successful Attempts for www* -->
  <row>
    <panel>
      <title>Failed vs. Successful Attempts - www*</title>
      <chart>
        <search>
          <query>index="user-test-index" source="tutorialdata.zip:./www*/secure.log" | eval status=case(searchmatch("Failed password"), "Failed", searchmatch("session opened"), "Successful") | stats count by status, source</query>
          <earliest>0</earliest>
          <latest>now</latest>
        </search>
        <option name="charting.chart">stackedBar</option>
        <option name="charting.legend.placement">bottom</option>
      </chart>
    </panel>
  </row>
</dashboard>
EAI_DATA

  acl {
    owner = "admin"
    app   = "search"
  }
}





