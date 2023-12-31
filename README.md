# Buttercup Games - Splunk Deployment with Terraform

## Introduction
The project's aim is to automate the deployment of Splunk Enterprise within AWS, utilizing a marketplace AMI and managing configurations through Terraform.

## Prerequisites
- AWS Free Tier account.
- AWS CLI installed on your local machine.
- Terraform installed on your local machine.
- An AMI ID from Splunk's AWS Marketplace image.

## Setup Instructions
1. **AWS Configuration:**
   Configure AWS credentials locally to allow Terraform to interact with the AWS account.
    - Install AWS CLI: 
         ```
          brew install awscli
          aws --version //To verify the version installed
         ```
    
    - Setup IAM User:
        - Sign In to AWS Console: Go to https://aws.amazon.com/ and log in.
        - Access IAM Dashboard: Navigate to "Services" > "Security, Identity, & Compliance" > "IAM".
        - Go to "Users" and "Add user".
        - Enable "Programmatic access".
        - Attach "AdministratorAccess".
        - Note the "Access key ID" and "Secret access key".
        
    - Configure AWS CLI:
      ```
      aws configure
      ```
      > Enter ACCESS_KEY, SECRET_KEY, Default region name(us-west-1), and Default output format(json) when prompted.

2. **Terraform Installation:**
    ```
     brew install terraform
     terraform -v //To verify the version
    ```
3. **Initialize Project:**
    ```
    mkdir my-terraform-project && cd my-terraform-project
    touch provider.tf //To create a provider.tf file
    touch main.tf //To create a main.tf file.
    ```

4. **Terraform Templates:**
 Below are the Terraform templates used in the project:
- `provider.tf`: Configures the AWS and Splunk providers.
   - AWS provider is set to the "us-west-1" region.
   - Splunk provider configuration includes the connection URL, credentials, and SSL verification settings.
- `main.tf`: Defines the resources for deploying and managing Splunk on AWS.
   - AWS Instance for Splunk: Deploys an EC2 instance with the [Splunk AMI](https://docs.splunk.com/Documentation/Splunk/latest/Admin/AbouttheSplunkAMI), sets the instance type, and applies tags. 
   - Security Group for Splunk: Sets up a custom security group with ingress rules for SSH (port 22), Splunk web interface (port 8000), and Splunk management port (port 8089), as well as an egress rule allowing all outbound traffic.
   - Splunk Resources:
     - Creates a new Splunk user with an admin role.
     - Establishes a new Splunk index for storing data.
     - Configures the HTTP Event Collector for data ingestion.
     - Generates an HTTP Event Collector token.
     - Defines saved searches for alerts and statistics.
     - Construct Splunk dashboard's for data visualization.


 5. **Deployment Steps:**
    ```
    terraform init
    terraform plan
    terraform apply -auto-approve
    ```
    
    
6. **AWS Infrastructure:**
    The following resources are provisioned for Splunk's infrastructure on AWS:
      1. EC2 Instance for Splunk
      2. Type: c5.large
      3. Key Pair: Splunk-test(created for this assignment)
      4. Security Group Configuration
            - A custom security group splunk_custom_sg is set up with ingress rules for SSH, Splunk web interface, and Splunk management ports.
   
8. **Access Splunk:**
   - Once the Terraform apply is successful, you'll get the public IP of the deployed EC2 instance. After the deployment, The instance is up to access the Splunk web interface on port 8000 (Example: http://$aws_public_ip:8000).

## Managing Splunk with Terraform
Terraform is used to manage Splunk configurations, such as:
   - Creating a new Splunk user
   - Setting up a new index
   - Configuring HTTP Event Collector (HEC)
   - Establishing a saved search
   - Creating dashboards for visualizations

## Bonus Features
- **Splunk Capabilities:** The project demonstrates creating users, indexes, setting up data inputs, creating saved searches and dashboards in Splunk.
- **Creating a User**
    - A new user, testuser, has been created in Splunk with administrative privileges.
    - Username: `testuser`
    - Email: user_email@example.com
    - Role: admin
    - This user can be found in Splunk by navigating to `Settings -> Users and Authentication -> Users`.

- **Creating an Index**
    - A new index called `user-test-index` is set up.
    - Index Name: `user-test-index`
    - Hot Buckets: 6
    - DB Size Limit: 976 GB upto
    - This index is visible under `Settings -> Data -> Indexes`.

- **HTTP Event Collector (HEC) Configuration**
    - A global HTTP Event Collector configuration is established with the following settings:
       - SSL Enabled: true
       - Port: 8088
       - Status: Enabled

- **HEC Token**
    - A token for the HTTP Event Collector is created to allow data ingestion:
       - Token Name: hec-token-01
       - Bound Index: user-test-index
       - Additional Indexes: ["user-test-index", "history", "summary"]
       - Source Type: aws:sourcetype
       - Source: aws:source
       - Owner: testuser
       - Access Control: Global read by admin, write by admin
       - This token will collect data and store it in the `user-test-index` index.

- **Saved Searches**
    - A saved search named `new-search-01` has been created,
        - Name: `new-search-01`
        - Owner: `testuser`
        - App Context: `Search & Reporting (search)`
        - Alert Actions: Email notifications
        - Search: Data from the `user-test-index` source `aws:hec-token-01`
        - Schedule: Every 15 minutes

    - A saved search named `Prices Statistics Search` has been created,
         - Name: `Prices Statistics Search`
         - Owner: `admin`
         - App Context: `Search & Reporting (search)`
         - Schedule: Every 2 hours
         - Search: This search provides average, minimum, and maximum price values from a lookup table prices.csv. 
> [!NOTE] 
> When filtering by owner, [ALL for new-search-01]() and [admin for Prices Statistics Search](), you can easily retrieve these searches within the `Search & Reporting(Search)` app context found under `Settings -> Knowledge -> Searches, Reports, and Alerts`.

- **Dashboards**:
   - `Terraform_Sample_Dashboard_Prices` has been created to visualize data from the `prices` lookup.
       - Panels:
          1. Product Prices Table:
              Displays a table of product IDs, names, prices, sale prices, and codes.
          2. Price vs Sale Price:
             Shows a bar chart representing the average difference between the price and sale price for each product.
          3. Price Distribution:
              Presents a column chart with the distribution of product prices by intervals of 10.
   
   - `Tutorial Data Analysis` has been added to provide visual insights into tutorialdata contained within the tutorialdata.zip file added to index `user-test-index` and is designed to assist users in analyzing various security and access logs to detect patterns and anomalies.
        - panels:
           1. Unique Users with Failed Attempts - mailsv: This panel displays the count of unique users who had failed login attempts on the mailsv server.
           2. Failed vs. Successful Attempts - mailsv: A bar chart representing the number of failed versus successful login attempts on the mailsv server.
           3. Top Requested Products - www1: Shows a bar chart with the most requested products, based on the logs from the www1 server.
           4. Volume of Traffic Over Time - www2: A line chart indicating the volume of traffic over time, sourced from www2 server access logs.
           5. Failed vs. Successful Attempts - www*: A stacked bar chart comparing failed and successful login attempts across all www servers.


- **Data Analysis for prices:** A sample dataset prices.csv is added as input look up, and basic analysis is presented using Splunk's searching and reporting capabilities below
 
    - ***Analysis-1:*** Summary of Products and Prices.
       - Objective: Provide a summary of the average, minimum, and maximum prices.
       - Search Query:
           ```
           | inputlookup prices 
           | stats avg(price) as AveragePrice, min(price) as MinPrice, max(price) as MaxPrice
           ```
        - Findings
           - The average price across all products is $23.24.
           - The minimum price of a product is $3.99.
           - The maximum price listed is $49.99.
    
    - ***Analysis-2:*** Price Difference Analysis.
       - Objective: Analyze the difference between the regular price and the sale price.
       - Search Query:
           ```
           | inputlookup prices 
           | eval PriceDifference = price - sale_price 
           | stats avg(PriceDifference) as AverageDifference, max(PriceDifference) as MaxDifference, min(PriceDifference) as MinDifference
           ```
       -  Findings
           - On average, products are $6.3125 cheaper on sale.
           - The largest discount offerd is $15.00 off the regular price.
           - The smallest discount amount is $2.00.
    
    - ***Analysis-3:*** Discount Percentage.
       - Objective: Calculate the percentage of discount provided on average.
       - Search Query:
           ```
           | inputlookup prices 
           | eval DiscountPercent = round(100 * (price - sale_price) / price, 2)
           | stats avg(DiscountPercent) as AverageDiscount
           ```
       - Findings:
           - The average discount percentage across all products is 30.59%.
    
    - ***Analysis-4:***  Product Count by Price Range.
       - Objective: Count how many products fall into various price ranges.
       
       - Search Query:
           ```
           | inputlookup prices 
           | bin price span=10 
           | stats count by price 
           ```
       - Findings:
           - 2 products are priced between $10-$20.
           - 5 products are in the $20-$30 price range, and so on.
    
    - ***Analysis-5:*** Sales Analysis.
       - Objective: Identify products with a sale price significantly lower than the regular price.
       - Search Query:
           ```
           | inputlookup prices 
           | where sale_price < 0.5 * price
           | table productId, product_name, price, sale_price
           ```
       - Findings
           - Puppies vs. Zombies, Holy Blade of Gouda. Fire Resistance Suit of Provolone products have sale price less than half of the regular price.


- **Data Analysis for tutorialdata in mailsv :** A sample dataset tutorialdata.zip is added as data, and is designed to assist users in analyzing various security and access logs to detect patterns and anomalies.
  - ***Analysis-1:*** Failed attempts
    - Objective: Count how many failed attempts have been made.
    - Search Query:
       ```
       |index="user-test-index" source="tutorialdata.zip:./mailsv/secure.log" "Failed password"
       | stats count as FailedAttempts
       ```
    - Findings
      - A total of 24,462 failed password attempts were recorded.
           
  - ***Analysis-2:*** Successful Logins:
    - Objective: Count the number of successful logins.
    - Search Query:
      ```
      index="user-test-index" source="tutorialdata.zip:./mailsv/secure.log" "session opened"
      | stats count as SuccessfulLogins

      ```
    - Findings
      - There were 1,557 successful login events.

