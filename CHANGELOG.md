# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [v1.3.3] - 2026-01-23

### ✨ Added
- **Enhanced CORS Support**: Comprehensive Cross-Origin Resource Sharing (CORS) configuration
  - Added `cors_allowed_origins` variable to control CORS allowed origins (default: `'*'`)
  - Added OPTIONS endpoints for all API Gateway resources (tables, primary keys, sort keys)
  - Implemented proper CORS preflight request handling
- **Centralized Response Parameter Management**: Streamlined API Gateway response configuration
  - Added centralized local variables for consistent CORS header management
  - Added method-specific response parameter configurations
  - Created reusable response parameter templates for different endpoint types

### 🔧 Changed
- **Standardized CORS Headers**: Replaced hardcoded CORS headers with centralized configuration
  - All API Gateway method responses now use consistent CORS header configuration
  - Moved from inline CORS definitions to reusable local variables
  - Updated all endpoint files to use centralized response parameter management
- **Enhanced API Gateway Structure**: Improved organization and maintainability
  - Added OPTIONS method support to `local.http_methods`
  - Standardized response parameter handling across all endpoints
  - Consistent CORS handling for GET, POST, PUT, DELETE, and OPTIONS methods

### 📁 New Files Added
- `apig-pkey-options.tf` - OPTIONS method configuration for primary key endpoints
- `apig-skey-options.tf` - OPTIONS method configuration for sort key endpoints  
- `apig-table-options.tf` - OPTIONS method configuration for table endpoints

### 🌐 CORS Configuration
- **Configurable Origins**: Set allowed origins via `cors_allowed_origins` variable
- **Method-Specific Headers**: Different CORS configurations for different endpoint types
  - GET/DELETE endpoints: `'OPTIONS,GET,DELETE'`
  - POST/PUT endpoints: `'OPTIONS,GET,POST,PUT'`
  - Comprehensive header support: `'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'`

### 🔄 Migration Notes
- This version is backward compatible with existing v1.3.2 installations
- CORS origins default to `'*'` (allow all) - customize via `cors_allowed_origins` variable
- No changes required to existing variable configurations
- Enhanced web browser compatibility with proper preflight request support

### 🎯 Breaking Changes
- None - This is a feature enhancement release that maintains full backward compatibility

---

## [v1.3.2] - 2026-01-19

### ✨ Added
- **Auto-Generate Unique IDs for Missing Keys**: New functionality to automatically generate unique identifiers when partition or sort keys are missing during item creation
  - Added `auto_unique_id_for_missing_keys` variable to control this behavior (default: false)
  - Added `generateUniqId()` function in POST Lambda that generates:
    - Timestamp-based numeric IDs (Date.now()) for Number type keys
    - UUID-based string IDs (crypto.randomUUID()) for String type keys
- **Key Type Validation**: Enhanced validation to ensure key values match their expected DynamoDB types
  - Added `validateKeyType()` function to check String vs Number type compatibility
  - Prevents runtime errors by validating key types before DynamoDB operations

---

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