/* *  * * * * * * * * * * * * * * * * * * * *
*  Function for DynamoDB-As-API
*  Developed by CloudPedia.AI
*  Created: 1/11/2026
*  Last Modified: 1/18/2026
*  Build Version 1.0.0
* * * * * * * * * * * * * * * * * * * * * * */
import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { DynamoDBDocumentClient, UpdateCommand } from "@aws-sdk/lib-dynamodb";

// Create DynamoDB client
const client = new DynamoDBClient({ region: "us-west-2" });
const dynamoDb = DynamoDBDocumentClient.from(client);
var item_not_found_msg = "No item found to update with the provided keys";

export const handler = async (event) => {
    const successCallback = (entity_name, addedItem) => {
        return {
            statusCode: 200,
            headers: {
                "Content-Type": "application/json",
                "Access-Control-Allow-Origin": "*"
            },
            body: JSON.stringify({
                message: "Updated existing item in " + entity_name + " successfully",
                item: addedItem
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
        if (sort_key) {
            item_not_found_msg = "No item found in " + entity_name + " with provided Partition key (" + partition_key + ") and Sort key (" + sort_key + ")";
        } else {
            item_not_found_msg = "No item found in " + entity_name + " with provided Partition key (" + partition_key + ")";
        }

        console.log("event", event);
        if (!event) {
            return errorCallback("No " + entity_name + " found in the request payload", 400);
        }

        const itemToUpdate = event.body;
        console.log("itemToUpdate", itemToUpdate);

        let partition_key_value = null;
        let sort_key_value = null;

        if ((partition_key in itemToUpdate) && itemToUpdate[partition_key]) {
            partition_key_value = itemToUpdate[partition_key];
        } else {
            return errorCallback("Partition key (" + partition_key + ") required to update existing item in " + entity_name, 400);
        }

        if (sort_key) {
            if ((sort_key in itemToUpdate) && itemToUpdate[sort_key]) {
                sort_key_value = itemToUpdate[sort_key];
            } else {
                return errorCallback("Sort key (" + sort_key + ") required to update existing item in " + entity_name, 400);
            }
        }

        // Prepare key object using partition & sort key/value pair
        var primaryKey = {};
        primaryKey[partition_key] = partition_key_value
        if (sort_key) {
            primaryKey[sort_key] = sort_key_value
        }
        console.log("primaryKey", primaryKey);

        // prepare update expression using all key/value placeholders
        var updateExpr = "set ";
        for (var key in itemToUpdate) {
            if (!(key in primaryKey)) {
                updateExpr += " #" + key + " = :v" + key + ",";
            }
        }
        // Removing last comma
        updateExpr = updateExpr.substring(0, updateExpr.length - 1);
        console.log("updateExpr", updateExpr);

        // prepare ExpressionAttributeNames using all keys
        var attNames = {};
        for (key in itemToUpdate) {
            if (!(key in primaryKey)) {
                var keyName = "#" + key;
                attNames[keyName] = key;
            }
        }
        console.log("attNames", attNames);
        if (Object.keys(attNames).length == 0) {
            return errorCallback("No attributes found in the payload to update " + entity_name, 400);
        }

        // prepare ExpressionAttributeValues using all values
        var attValues = {};
        for (key in itemToUpdate) {
            var keyVal = ":v" + key;
            attValues[keyVal] = itemToUpdate[key];
        }
        console.log("attValues", attValues);

        // const condition_expression = "client_id = :vclient_id AND queue_id = :vqueue_id";
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
            UpdateExpression: updateExpr,
            ExpressionAttributeNames: attNames,
            ExpressionAttributeValues: attValues,
            ConditionExpression: conditionExpr,
            ReturnValues: "ALL_NEW"
        };
        console.log("params: ", params);

        // Put item in DynamoDB
        await dynamoDb.send(new UpdateCommand(params));

        // success response
        return successCallback(entity_name, itemToUpdate);

    } catch (error) {
        console.error("Error adding item:", error.name);
        if (error.name == "ConditionalCheckFailedException") {
            // user error response
            return errorCallback(item_not_found_msg, 404);
        } else {
            // server error response
            return errorCallback(error.message, 500);
        }
    }
};