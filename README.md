# AWS DynamoDB as API
This terraform module will create a REST API with full CRUD operations (Create, Read, Update, Delete) for your DynamoDB tables. You just provide the list of DynamoDB tables, this module will read schema of all tables and will generate endpoints accordingly.

## ✨ Key Features
- **Full CRUD Operations**: Complete Create, Read, Update, Delete functionality
- **Auto-Schema Detection**: Automatically reads DynamoDB table schemas
- **Smart Key Management**: Auto-generation of unique IDs for missing keys
- **Type Validation**: Ensures key values match DynamoDB types (String/Number)
- **Sort Key Awareness**: Intelligent handling of tables with and without sort keys
- **Custom Domain Support**: Optional custom domain configuration
- **Cognito Authorization**: Built-in support for Cognito user pools


# Links

- [Documentation](https://cloudpedia.ai/terraform-module/aws-dynamodb-as-api/)
- [Terraform module](https://registry.terraform.io/modules/cloudpediaai/dynamodb-as-api/aws/latest)
- [GitHub Repo](https://github.com/CloudPediaAI/terraform-aws-dynamodb-as-api)


# Release Notes
## v1.3.2
### Changes/Updates
Enhanced CRUD operations with automatic unique ID generation and key type validation. For detailed changes, see [CHANGELOG.md](CHANGELOG.md#v132).

### Key Features Added
- **Auto-Generate Unique IDs**: Automatically generate unique identifiers for missing partition or sort keys during item creation
- **Key Type Validation**: Enhanced validation to ensure key values match their expected DynamoDB types (String vs Number)
- **Smart ID Generation**: 
  - Timestamp-based numeric IDs for Number type keys
  - UUID-based string IDs for String type keys
- **Enhanced Error Handling**: Better validation messages and type-specific error responses

### Input Variable Changes
#### 1. auto_unique_id_for_missing_keys
New boolean variable to control automatic unique ID generation for missing keys during POST operations.
```hcl
variable "auto_unique_id_for_missing_keys" {
  type        = bool
  default     = false
  description = "Automatically generate a Unique ID if Partition Key or Sort Key is missing while doing Adding New Items"
}
```

### Output Variable Changes
None

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



