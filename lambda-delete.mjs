/* *  * * * * * * * * * * * * * * * * * * * *
*  Function for DynamoDB-As-API
*  Developed by CloudPedia.AI
*  Created: 1/11/2026
*  Last Modified: 1/18/2026
*  Build Version 1.0.0
* * * * * * * * * * * * * * * * * * * * * * */
import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { DynamoDBDocumentClient, DeleteCommand } from "@aws-sdk/lib-dynamodb";

const client = new DynamoDBClient({ region: "us-west-2" });
const dynamoDb = DynamoDBDocumentClient.from(client);

var item_not_found_msg = "No item found to delete with the provided keys";

export const handler = async (event) => {
    const successCallback = (entity_name, deletedItem) => {
        return {
            statusCode: 200,
            headers: {
                "Content-Type": "application/json",
                "Access-Control-Allow-Origin": "*"
            },
            body: JSON.stringify({
                message: "Deleted item from " + entity_name + " successfully",
                item: deletedItem
            })
        };
    };
    const errorCallback = (message, errorCode = 500) => {
        const errorResponse = JSON.stringify({
            errorName: "ERROR_" + errorCode,
            errorCode: errorCode,
            headers: {
                "Content-Type": "application/json",
                "Access-Control-Allow-Origin": "*"
            },
            status: "failed",
            errorMessage: message
        });
        throw new Error(errorResponse);
    };

    try {
        const action_name = event.action_name;
        const entity_name = event.entity_name.toUpperCase();
        const table_name = event.table_name;
        const partition_key = event.partition_key;
        const sort_key = event.sort_key;
        const partition_key_value = event.partition_key_value;
        const sort_key_value = event.sort_key_value;

        if (sort_key) {
            item_not_found_msg = "No item found in " + entity_name + " with provided Partition key (" + partition_key + ") and Sort key (" + sort_key + ")";
        } else {
            item_not_found_msg = "No item found in " + entity_name + " with provided Partition key (" + partition_key + ")";
        }

        if (!partition_key_value){
            return errorCallback("Partition key (" + partition_key + ") required to delete existing item from " + entity_name, 400);
        }

        if (sort_key) {
            if (!sort_key_value) {
                return errorCallback("Sort key (" + sort_key + ") required to delete existing item from " + entity_name, 400);
            }
        }

        // Prepare key object using partition & sort key/value pair
        var primaryKey = {};
        primaryKey[partition_key] = partition_key_value
        if (sort_key) {
            primaryKey[sort_key] = sort_key_value
        }
        console.log("primaryKey", primaryKey);

        // prepare ExpressionAttributeValues using all values
        var attValues = {};
        for (var key in primaryKey) {
            var keyVal = ":v" + key;
            attValues[keyVal] = primaryKey[key];
        }
        console.log("attValues", attValues);

        var conditionExpr = "";
        for (var key in primaryKey) {
            if (conditionExpr.length > 0) {
                conditionExpr += " AND ";
            }
            conditionExpr += key + " = :v" + key;
        }
        console.log("conditionExpr", conditionExpr);

        const params = {
            TableName: table_name,
            Key: primaryKey,
            ExpressionAttributeValues: attValues,
            ConditionExpression: conditionExpr,
            ReturnValues: 'ALL_OLD'
        };
        console.log("params: ", params);

        // Put item in DynamoDB
        const result = await dynamoDb.send(new DeleteCommand(params));
        const deletedItem = result.Attributes
        
        // success response
        return successCallback(entity_name, deletedItem);

    } catch (error) {
        console.error("Error deleting item:", error.name);
        if (error.name == "ConditionalCheckFailedException") {
            // user error response
            return errorCallback(item_not_found_msg, 404);
        } else {
            // server error response
            return errorCallback(error.message, 500);
        }
    }
};