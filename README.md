# Buttercup Games - Splunk Deployment with Terraform

## Introduction
The project's aim is to automate the deployment of Splunk Enterprise within AWS, utilizing a marketplace AMI and managing configurations through Terraform.

## Prerequisites
- AWS Free Tier account
- Terraform installed on your local machine
- An AMI ID from Splunk's AWS Marketplace image 

## Setup Instructions
1. **AWS Configuration:**
   Configure AWS credentials locally to allow Terraform to interact with the AWS account.
    - Install AWS CLI: 
         ```
          brew install awscli
          aws --version [To verify the version]: #
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

2. **Terraform Initialization:**
    ```
     brew install terraform
     terraform -v [To verify the version]: #
    ```
3. **Initialize Project:**
    ```
    mkdir my-terraform-project && cd my-terraform-project
    touch provider.tf [To create a provider.tf file]: #
    touch main.tf [To create a main.tf file.]: #
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
     - Constructs a Splunk dashboard for data visualization.


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
        3. Key Pair: Splunk-test
        4. Security Group Configuration
            - A custom security group splunk_custom_sg is set up with ingress rules for SSH, Splunk web interface, and Splunk management ports.

4. **Access Splunk:**
Once the Terraform apply is successful, you'll get the public IP of the deployed EC2 instance. After the deployment. the instance is up to access the Splunk web interface on port 8000 (Example: http://$aws_public_ip:8000).

## Managing Splunk with Terraform
Terraform is used to manage Splunk configurations, such as:
- Creating a new Splunk user
- Setting up a new index
- Configuring HTTP Event Collector (HEC)
- Establishing a saved search
- Creating a dashboard for visualizations

## Bonus Features
- **Splunk Capabilities:** The project demonstrates creating users, indexes, setting up data inputs, creating saved searches and dashboard in Splunk.
- **Creating a User**
    A new user, testuser, has been created in Splunk with administrative privileges:
    Username: `testuser`
    Email: user_email@example.com
    Role: admin
    This user can be found in Splunk by navigating to `Settings -> Users and Authentication -> Users`.

- **Creating an Index**
    A new index called `user-test-index` is set up:
    Index Name: `user-test-index`
    Hot Buckets: 6
    DB Size Limit: 976 GB upto
    This index is visible under `Settings -> Data -> Indexes`.

- **HTTP Event Collector (HEC) Configuration**
    A global HTTP Event Collector configuration is established with the following settings:
    SSL Enabled: true
    Port: 8088
    Status: Enabled

- **HEC Token**
    A token for the HTTP Event Collector is created to allow data ingestion:
    Token Name: hec-token-01
    Bound Index: user-test-index
    Additional Indexes: ["user-test-index", "history", "summary"]
    Source Type: aws:sourcetype
    Source: aws:source
    Owner: testuser
    Access Control: Global read by admin, write by admin
    This token will collect data and store it in the `user-test-index` index.

- **Saved Searches**
    A saved search named `new-search-01` has been created:
    Owner: testuser
    Alert Actions: Email notifications
    Search: Data from the user-test-index source aws:hec-token-01
    Schedule: Every 15 minutes
    This saved search can be found under `Settings -> Knowledge -> Searches, Reports, and Alerts`.

    `Prices Statistics Search`
    Another saved search named Prices Statistics Search calculates statistics on product prices:
    Schedule: Every 2 hours
    Owner: admin
    This search provides average, minimum, and maximum price values from a lookup table prices.csv.

- **Dashboard**: `Terraform_Sample_Dashboard_Prices`
     Terraform_Sample_Dashboard_Prices has been created to visualize data from the `prices` lookup.
    Panels:
    1. Product Prices Table:
        Displays a table of product IDs, names, prices, sale prices, and codes.
    2. Price vs Sale Price:
       Shows a bar chart representing the average difference between the price and sale price for each product.
    3. Price Distribution:
        Presents a column chart with the distribution of product prices by intervals of 10.


- **Data Analysis:** A sample dataset prices.csv is added as input look up, and basic analysis is presented using Splunk's searching and reporting capabilities below
 
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




