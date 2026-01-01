/* *  * * * * * * * * * * * * * * * * * * * *
*  Function for DynamoDB-As-API
*  Developed by CloudPedia.AI
*  Created: 5/1/2024
*  Last Modified: 5/1/2024
*  Build Version 1
* * * * * * * * * * * * * * * * * * * * * * */
// const utils = require('./lib/utils');
// const dynDbDataHelper = require('./ddb-data-helper');
// const db = require('./lib/ddb');
// const dynDbSchemaHelper = require('./ddb-schema-helper');
// const db = require('./lib/ddb-doc-client');

exports.handler = (event, context, callback) => {
    const successCallback = (res) => callback(null, res);
    const errorCallback = (err, code) => callback(JSON.stringify({
        errorCode: code ? code : 400,
        errorMessage: err ? err.message : err
    }));

    var httpMethod = utils.getParamValue(event, "httpMethod", true, callback);
    if(httpMethod == "ERROR-BODY"){
        errorCallback(new Error("Request body is not a valid JSON"), 400);
    }
    var action = utils.getParamValue(event, "action", true, callback);
    var collectionId = utils.getParamValue(event, "collectionId", false, callback);
    var awsRegion = utils.getParamValue(event, "awsRegion", false, callback);
    var tableName = utils.getParamValue(event, "tableName", true, callback);
    var body = null;
    var userId = utils.getParamValue(event, "userId", false, callback);
    var dynamodb = null;
    var dbName = null;
    var modelName = null;
    var entityId = null;

    if(httpMethod == "POST"){
        body = getParamValue(event, "body", true, callback);
        addEntity(awsRegion, tableName, collectionId, dbName, modelName, body, userId, successCallback, errorCallback);
    }else{
        errorCallback(new Error("Unsupported method: " + httpMethod));
    }

};

function getParamValue(params, paramName, isRequired, callback){
    var paramValue = null;
    if(params){
        paramValue = params[paramName];
    }
    if(paramValue){
        return paramValue;
    }else{
        if(isRequired){
            callback("Value for <"+paramName+"> not provided");
        }else{
            return null;
        }
    }
}

function prepareEntityItemToAdd(collectionId, dbName, modelName, entityId, entity, userId, successCallback, errorCallback){

    var currTime = (new Date()).toISOString();
    var entityPath = "/" + dbName + "/" + modelName + "/" + "_id" + "/" + entityId;
    var newItem = {
            "fdb___type": "entity",
    	    "fdb___collId": collectionId,
    	    "fdb___entityId": entityId,
    	    "fdb___path": entityPath,
            "fdb___createdOn": currTime,
            "fdb___createdBy": userId,
            "fdb___lastModifiedOn": currTime,
            "fdb___lastModifiedBy": userId
        };

    for(var key in entity){
        if(key && key.substring(0,1) != "_"){
            var keyName = utils.makeURLCompatible(key);
            var keyValue = entity[key];
            // var keyType = getDynamoDBType(keyValue);
            if(keyValue){
                newItem[keyName] = keyValue;
            }
        }
    }
    
    return newItem;
}

function addEntity(awsRegion, tableName, collectionId, dbName, modelName, entity, userId, successCallback, errorCallback){
    if(!entity){
        errorCallback(new Error("Entity is empty!"));
        return;
    }else{
        var allKeys = Object.keys(entity);
        if(allKeys.length==0){
            errorCallback(new Error("Entity is empty!"));
            return;
        }
    }

    // dbName = utils.makeURLCompatible(dbName);
    var modelPath = "/" + dbName + "/" + modelName;
    collectionId = collectionId + "-" + dbName + "-" + modelName;
    var entityId = entity._id;
    if(!entityId){
        var d = new Date();
        entityId = modelName + d.getTime();
    }

    var newItem = prepareEntityItemToAdd(collectionId, dbName, modelName, entityId, entity, userId, successCallback, errorCallback);
    // successCallback(newItem);
    // return;
    
    var params = { 
        TableName: tableName,
        ConditionExpression: "fdb___collId <> :v1 AND fdb___entityId <> :v2",
        ExpressionAttributeValues: {
            ":v1": collectionId,
            ":v2": entityId
        },
        ReturnValues: "NONE",
        Item: newItem
    };
    
    // successCallback(params);
    // return;

    var dynamodb = ddb.getDB(awsRegion);
    dynamodb.put(params, function(err, data) {
        if (err) {
            console.log(err); // an error occurred
            if(err.code == "ConditionalCheckFailedException"){
                errorCallback(new Error("Another <" + modelPath + "> found with same Id!"));
            }else{
                errorCallback(err);
            }
        } else {     
            console.log(data);           // successful response
            ddb.getItem(dynamodb, tableName, collectionId, dbName, entityId, "entity", successCallback, errorCallback);
        }
    });    
    
}
