trigger BidTrigger on Bid__c (after insert, after update, after delete, after undelete)//before insert, 
 {

    Map<ID, Item__c> itemsToUpdate = new Map<ID, Item__c>();
    Map<ID, Donation__c> donationsToUpdate = new Map<ID, Donation__c>();
        BidManager.dispatcher(trigger.isDelete, trigger.isInsert,
          trigger.isUpdate, trigger.isUndelete, trigger.isBefore, trigger.isAfter, trigger.new, trigger.newmap, trigger.old, trigger.oldmap, donationsToUpdate, itemsToUpdate);
}