/* *  * * * * * * * * * * * * * * * * * * * *
*  Function for DynamoDB-As-API
*  Developed by CloudPedia.AI
*  Created: 1/11/2026
*  Last Modified: 1/18/2026
*  Build Version 1.0.0
* * * * * * * * * * * * * * * * * * * * * * */
import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { DynamoDBDocumentClient, PutCommand } from "@aws-sdk/lib-dynamodb";
import crypto from 'crypto';

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
                status: "success",
                message: "New item added to " + entity_name + " successfully",
                added_item: addedItem
            })
        };
    };

    const errorCallback = (errorMessage, errorCode = 500) => {
        return {
            statusCode: errorCode,
            headers: {
                "Content-Type": "application/json",
                "Access-Control-Allow-Origin": "*"
            },
            body: JSON.stringify({
                errorName: "ERROR_" + errorCode,
                errorCode: errorCode,
                status: "error",
                message: errorMessage
            })
        };
    };

    const generateUniqId = (key_type) => {
        if (key_type === "N") {
            return Date.now();
        } else {
            return crypto.randomUUID();
        }
    }

    const validateKeyType = (entity_name, key_name, key_type, key_value) => {
        if(key_type === "N" && typeof key_value === "string") {
            errorCallback("Value of Key <" + key_name + "> must be a number for " + entity_name, 400);
        }
        if(key_type === "S" && typeof key_value === "number") {
            errorCallback("Value of Key <" + key_name + "> must be a string for " + entity_name, 400);
        }
    }

    try {
        if (!event) {
            return errorCallback("No payload found!", 400);
        }
        const action_name = event.action_name;
        const entity_name = event.entity_name.toUpperCase();
        const table_name = event.table_name;
        const partition_key = event.partition_key;
        const partition_key_type = event.partition_key_type;
        const sort_key = event.sort_key;
        const sort_key_type = event.sort_key_type;
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
            validateKeyType(entity_name, partition_key, partition_key_type, partition_key_value);
        } else {
            if (process.env.AUTO_GEN_UNIQ_ID_FOR_MISSING_KEYS === "true") {
                partition_key_value = generateUniqId(partition_key_type);
                itemToAdd[partition_key] = partition_key_value;
            } else {
                return errorCallback("Partition key <" + partition_key + "> is required to add a new " + entity_name, 400);
            }
        }

        if (sort_key && ((sort_key in itemToAdd) && itemToAdd[sort_key])) {
            sort_key_value = itemToAdd[sort_key];
            validateKeyType(entity_name, sort_key, sort_key_type, sort_key_value);
        } else {
            if (process.env.AUTO_GEN_UNIQ_ID_FOR_MISSING_KEYS === "true") {
                sort_key_value = generateUniqId(sort_key_type);
                itemToAdd[sort_key] = sort_key_value;
            } else {
                return errorCallback("Sort key <" + sort_key + "> is required to add a new " + entity_name, 400);
            }
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