# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [v1.3.0] - 2026-01-18

### ✨ Added
- **Full CRUD Operations Support**: Extended the module from read-only to support Create, Update, and Delete operations
  - Added POST endpoints for creating new items in DynamoDB tables
  - Added PUT endpoints for updating existing items in DynamoDB tables  
  - Added DELETE endpoints for removing items from DynamoDB tables
- **New Lambda Functions**:
  - `lambda-post.mjs` - Handles item creation with duplicate validation
  - `lambda-put.mjs` - Handles item updates with existence validation
  - `lambda-delete.mjs` - Handles item deletion with sort-key awareness
- **Enhanced API Gateway Configuration**:
  - Added API Gateway deployment automation (`apig-deploy.tf`)
  - Added POST method configurations (`apig-table-post.tf`)
  - Added PUT method configurations (`apig-table-put.tf`)
  - Added DELETE method configurations for both primary key and sort key operations
  - Added proper HTTP method responses (200, 400, 500) for all endpoints
- **Smart Delete Operations**: Added logic to prevent delete operations on tables with sort keys when only primary key is provided

### 🔧 Changed
- **Streamlined API Gateway Structure**: Refactored API Gateway configuration for better maintainability
  - Split endpoint configurations into separate files for better organization
  - Updated existing GET endpoint configurations for consistency
- **Enhanced IAM Permissions**: Updated IAM roles to include permissions for write operations (PutItem, UpdateItem, DeleteItem)
- **Improved Error Handling**: Enhanced error responses across all operations with proper HTTP status codes
- **Updated Documentation**: Modified README.md to reflect new CRUD capabilities

### 📁 New Files Added
- `apig-deploy.tf` - API Gateway deployment configuration
- `apig-table-post.tf` - POST method API Gateway configuration
- `apig-table-put.tf` - PUT method API Gateway configuration  
- `apig-pkey-delete.tf` - DELETE method API Gateway configuration for primary key
- `apig-skey-delete.tf` - DELETE method API Gateway configuration for sort key
- `lambda-post.mjs` - Lambda function for POST operations
- `lambda-post.tf` - Terraform configuration for POST Lambda
- `lambda-put.mjs` - Lambda function for PUT operations
- `lambda-put.tf` - Terraform configuration for PUT Lambda
- `lambda-delete.mjs` - Lambda function for DELETE operations
- `lambda-delete.tf` - Terraform configuration for DELETE Lambda

### 📊 Statistics
- **18 files changed** with **1,498 insertions** and **108 deletions**
- **Net addition**: ~1,400 lines of code
- **7 new files** added to support CRUD operations
- **3 new Lambda functions** implemented

### 🔄 Migration Notes
- This version is backward compatible with existing v1.2.0 installations
- No changes required to existing variable configurations
- New CRUD endpoints will be automatically available after upgrade
- Existing GET operations remain unchanged and fully functional

### 🎯 Breaking Changes
- None - This is a feature addition release that maintains full backward compatibility

---

## Previous Versions

### [v1.2.0] - Previous Release
### Changes/Updates
- Various enhancements and improvements

### [v1.1.0] - Previous Release  
### Changes/Updates
- Enhanced module to retrieve data from both Global and Local Secondary Indexes
- Added `index_name` parameter to `dynamodb_tables` variable

### [v1.0.0] - Initial Release
### Features Released
- GET endpoints for all Tables
- Cognito User Pool Authorizer 
- Custom Domain