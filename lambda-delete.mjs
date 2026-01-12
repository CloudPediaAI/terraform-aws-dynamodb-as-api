/* *  * * * * * * * * * * * * * * * * * * * *
*  Function for DynamoDB-As-API
*  Developed by CloudPedia.AI
*  Created: 1/11/2026
*  Last Modified: 1/11/2026
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
    const errorCallback = (error, errorCode = 500) => {
        return JSON.stringify({
            headers: {
                "Content-Type": "application/json",
                "Access-Control-Allow-Origin": "*"
            },
            errorCode: errorCode,
            errorMessage: error.message
        });
    };

    try {
        const action_name = event.action_name;
        const entity_name = event.entity_name;
        const table_name = event.table_name;
        const partition_key = event.partition_key;
        const sort_key = event.sort_key;
        if (sort_key) {
            item_not_found_msg = "No item found in " + entity_name + " with provided Partition key (" + partition_key + ") and Sort key (" + sort_key + ")";
        } else {
            item_not_found_msg = "No item found in " + entity_name + " with provided Partition key (" + partition_key + ")";
        }

        // console.log("body", event);
        // if(!event){
        //     return errorCallback(new Error("Keys not found to delete item from "+entity_name, 400));
        // }

        const itemToDelete = event.body;
        let partition_key_value = null;
        let sort_key_value = null;

        if ((partition_key in itemToDelete) && itemToDelete[partition_key]) {
            partition_key_value = itemToDelete[partition_key];
        } else {
            return errorCallback(new Error("Partition key (" + partition_key + ") required to delete existing item from " + entity_name), 400);
        }

        if (sort_key) {
            if ((sort_key in itemToDelete) && itemToDelete[sort_key]) {
                sort_key_value = itemToDelete[sort_key];
            } else {
                return errorCallback(new Error("Sort key (" + sort_key + ") required to update existing item from " + entity_name), 400);
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

        // var condition_expression = "client_id = :vclient_id AND queue_id = :vqueue_id";
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
            ConditionExpression: conditionExpr
        };
        console.log("params: ", params);

        // Put item in DynamoDB
        await dynamoDb.send(new DeleteCommand(params));

        // success response
        return successCallback(entity_name, itemToDelete);

    } catch (error) {
        console.error("Error adding item:", error.name);
        if (error.name == "ConditionalCheckFailedException") {
            // user error response
            return errorCallback(new Error(item_not_found_msg), 400);
        } else {
            // server error response
            return errorCallback(error);
        }
    }
};