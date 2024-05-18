# AWS DynamoDB as API
This terraform module will create a REST API to Read items from your DynamoDB tables (Create, Update, Delete will be added soon).  You just provide the list of Dynamodb tables, this module will read schema of all tables and will generate endpoints accordingly.


# Links

- [Documentation](https://cloudpedia.ai/terraform-module/aws-dynamodb-as-api/)
- [Terraform module](https://registry.terraform.io/modules/cloudpediaai/dynamodb-as-api/aws/latest)
- [GitHub Repo](https://github.com/CloudPediaAI/terraform-aws-dynamodb-as-api)


# Release Notes
## v1.1.0
### Changes/Updates
Enhanced this module to retrieve data from both Global and Local Seconday Indexes of any DynamoDB table

### Input Variable Changes
#### 1. dynamodb_tables
Included **index_name** in the map(object) to enable data retrieval from **Global secondary indexes**.  
```
    map(object({
        table_name         = string
        index_name         = string
        allowed_operations = string
    }))
```
Important:  You have to modify your current variable input to include **index_name = null** to continue retrieving data from the table

### Output Variable Changes
None


## v1.0.0
Features released
- GET endpoints for all Tables
- Cognito User Pool Authorizer 
- Custom Domain



