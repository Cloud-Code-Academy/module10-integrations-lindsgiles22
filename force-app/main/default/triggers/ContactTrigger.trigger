/**
 * ContactTrigger Trigger Description:
 * 
 * The ContactTrigger is designed to handle various logic upon the insertion and update of Contact records in Salesforce. 
 * 
 * Key Behaviors:
 * 1. When a new Contact is inserted and doesn't have a value for the DummyJSON_Id__c field, the trigger generates a random number between 0 and 100 for it.
 * 2. Upon insertion, if the generated or provided DummyJSON_Id__c value is less than or equal to 100, the trigger initiates the getDummyJSONUserFromId API call.
 * 3. If a Contact record is updated and the DummyJSON_Id__c value is greater than 100, the trigger initiates the postCreateDummyJSONUser API call.
 * 
 * Best Practices for Callouts in Triggers:
 * 
 * 1. Avoid Direct Callouts: Triggers do not support direct HTTP callouts. Instead, use asynchronous methods like @future or Queueable to make the callout.
 * 2. Bulkify Logic: Ensure that the trigger logic is bulkified so that it can handle multiple records efficiently without hitting governor limits.
 * 3. Avoid Recursive Triggers: Ensure that the callout logic doesn't result in changes that re-invoke the same trigger, causing a recursive loop.
 * 
 * Optional Challenge: Use a trigger handler class to implement the trigger logic.
 */
trigger ContactTrigger on Contact(before insert, after insert, after update) {
    // Check for trigger types before processing
    if (Trigger.isBefore && Trigger.isInsert) {
        for (Contact c: Trigger.new) {
            if (c.DummyJSON_Id__c == null || !c.DummyJSON_Id__c.isNumeric()) {
                // Generate a random number between 0 and 100
                Integer randomNumber = Math.mod(Crypto.getRandomInteger(), 101);
                // Ensure value is valid numeric string
                c.DummyJSON_Id__c = String.valueOf(randomNumber);
            }
        }
    }

    if (Trigger.isAfter) {
        for (Contact c: Trigger.new) {
            // Check if DummyJSON_Id__c is a valid numeric string
            if (c.DummyJSON_Id__c != null && !String.isEmpty(c.DummyJSON_Id__c)) {
                try {
                    Integer dummyId = Integer.valueOf(c.DummyJSON_Id__c);

                    // If the DummyJSON_Id__c is a valid number, proceed with the logic
                    if (dummyId <= 100 && Trigger.isInsert) {
                        // Trigger the API call if it's an insert and the DummyJSON_Id__c is valid
                        DummyJSONCallout.getDummyJSONUserFromId(c.DummyJSON_Id__c);
                    } else if (dummyId > 100 && Trigger.isUpdate) {
                        // Trigger the API call if it's an update and the DummyJSON_Id__c is greater than 100
                        DummyJSONCallout.postCreateDummyJSONUser(c.Id);
                    }
                } catch (Exception e) {
                    // Log any errors related to invalid numeric values
                    System.debug('Error: DummyJSON_Id__c is not a valid numeric string. Contact Id: ' + c.ID + ' Error: ' + e.getMessage());
                }
            }
        }
    }
}
