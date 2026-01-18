# AWS DynamoDB as API
This terraform module will create a REST API with full CRUD operations (Create, Read, Update, Delete) for your DynamoDB tables. You just provide the list of Dynamodb tables, this module will read schema of all tables and will generate endpoints accordingly.


# Links

- [Documentation](https://cloudpedia.ai/terraform-module/aws-dynamodb-as-api/)
- [Terraform module](https://registry.terraform.io/modules/cloudpediaai/dynamodb-as-api/aws/latest)
- [GitHub Repo](https://github.com/CloudPediaAI/terraform-aws-dynamodb-as-api)


# Release Notes
## v1.3.0
### Changes/Updates
Added full CRUD operations support (Create, Update, Delete) to complement existing Read operations. For detailed changes, see [CHANGELOG.md](CHANGELOG.md#v130).

### Key Features Added
- POST endpoints for creating new items
- PUT endpoints for updating existing items  
- DELETE endpoints for removing items
- Enhanced error handling and validation
- Smart delete operations with sort-key awareness

### Input Variable Changes
None - Fully backward compatible

### Output Variable Changes
None

## v1.2.0
### Changes/Updates

### Input Variable Changes
#### 1. 

### Output Variable Changes
None



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



