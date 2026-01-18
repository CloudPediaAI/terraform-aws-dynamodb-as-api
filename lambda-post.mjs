/* *  * * * * * * * * * * * * * * * * * * * *
*  Function for DynamoDB-As-API
*  Developed by CloudPedia.AI
*  Created: 1/11/2026
*  Last Modified: 1/18/2026
*  Build Version 1.0.0
* * * * * * * * * * * * * * * * * * * * * * */
import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { DynamoDBDocumentClient, PutCommand } from "@aws-sdk/lib-dynamodb";

// Create DynamoDB client
const client = new DynamoDBClient({ region: "us-west-2" });
const dynamoDb = DynamoDBDocumentClient.from(client);
var item_already_exists_msg = "Item already exists";

export const handler = async (event) => {
    const successCallback = (entity_name, addedItem) => {
        return {
            statusCode: 200,
            headers: {
                "Content-Type": "application/json",
                "Access-Control-Allow-Origin": "*"
            },
            body: JSON.stringify({
                message: "New item added to " + entity_name + " successfully",
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
        if (!event) {
            return errorCallback("No payload found!", 400);
        }
        const action_name = event.action_name;
        const entity_name = event.entity_name.toUpperCase();
        const table_name = event.table_name;
        const partition_key = event.partition_key;
        const sort_key = event.sort_key;
        const itemToAdd = event.body;
        console.log("itemToAdd", itemToAdd);

        if (!itemToAdd) {
            return errorCallback("No " + entity_name + " data found in the request payload", 400);
        }

        const condition_expression = "attribute_not_exists(" + partition_key + ")";
        item_already_exists_msg = "Another item found in " + entity_name + " with the provided keys!"

        let partition_key_value = null;
        let sort_key_value = null;

        if ((partition_key in itemToAdd) && itemToAdd[partition_key]) {
            partition_key_value = itemToAdd[partition_key];
        } else {
            return errorCallback("Partition key <" + partition_key + "> required to add new " + entity_name, 400);
        }

        if (sort_key && ((sort_key in itemToAdd) && itemToAdd[sort_key])) {
            sort_key_value = itemToAdd[sort_key];
        } else {
            return errorCallback("Sort key <" + sort_key + "> required to add new " + entity_name, 400);
        }

        // Parameters for DynamoDB PutCommand
        const params = {
            TableName: table_name,
            Item: itemToAdd,
            ConditionExpression: condition_expression,
            ReturnValues: "NONE"
        };

        // Add item to DynamoDB using PutCommand
        await dynamoDb.send(new PutCommand(params));

        // success response
        return successCallback(entity_name, itemToAdd);

    } catch (error) {
        console.error("Error adding item:", error.name);
        if (error.name == "ConditionalCheckFailedException") {
            // input error response
            return errorCallback(item_already_exists_msg, 400);
        } else {
            // server error response
            return errorCallback(error.message, 500);
        }
    }
};