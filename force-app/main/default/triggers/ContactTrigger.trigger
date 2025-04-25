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
    if (Trigger.isBefore && Trigger.isInsert) {
        assignRandomDummyIds(Trigger.new);
    }

    if (Trigger.isAfter && Trigger.isInsert) {
        List<Contact> toUpdate = new List<Contact>();

        for (Contact c : Trigger.new) {
            if (c.DummyJSON_Id__c == null || !c.DummyJSON_Id__c.isNumeric()) {
                toUpdate.add(c);
            }
        }

        if (!toUpdate.isEmpty()) {
            assignRandomDummyIds(toUpdate);
			List<Id> toUpdateIds = new List<Id>();
			for (Contact c : toUpdate) {
				toUpdateIds.add(c.Id);
			}
            updateDummyJSONIdInFuture(toUpdateIds);
        }
    }

    if (Trigger.isAfter && Trigger.isUpdate) {
        for (Contact c : Trigger.new) {
            if (c.DummyJSON_Id__c != null && !String.isEmpty(c.DummyJSON_Id__c)) {
                try {
                    Integer dummyId = Integer.valueOf(c.DummyJSON_Id__c);
                    if (dummyId <= 100 && Trigger.isInsert) {
                        DummyJSONCallout.getDummyJSONUserFromId(c.DummyJSON_Id__c);
                    } else if (dummyId > 100 && Trigger.isUpdate) {
                        DummyJSONCallout.postCreateDummyJSONUser(c.Id);
                    }
                } catch (Exception e) {
                    System.debug('Error: DummyJSON_Id__c is not a valid numeric string. Contact Id: ' + c.Id + ' Error: ' + e.getMessage());
                }
            }
        }
    }
// Helper method to assign random DummyJSON_Id__c
private static void assignRandomDummyIds(List<Contact> contacts) {
    for (Contact c : contacts) {
        if (c.DummyJSON_Id__c == null || !c.DummyJSON_Id__c.isNumeric()) {
            Integer randomNumber = Math.mod(Crypto.getRandomInteger(), 101);
            c.DummyJSON_Id__c = String.valueOf(randomNumber);
        }
    }
}
// Future method to handle updates after insert to avoid the read only state error
@future
public static void updateDummyJSONIdInFuture(List<Id> contactIds) {
	List<Contact> contactsToUpdate = [SELECT Id, DummyJSON_Id__c FROM Contact WHERE Id IN :contactIds];
	update contactsToUpdate;
}
}

