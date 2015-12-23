//KK: Any recursion cases that need to be checked?
//KK: To check if Donation lookup has changed? To avoid One donation having more than one bids for the same item?

trigger BidTrigger on Bid__c (after insert, after update, after delete, after undelete) {

Map<ID, Item__c> itemsToUpdate = new Map<ID, Item__c>();
Map<ID, Donation__c> donationsToUpdate = new Map<ID, Donation__c>();


DonationCalculator.calculateTotalDonation(trigger.isDelete, trigger.isInsert,
                                          trigger.isUpdate, trigger.isUndelete, trigger.new, trigger.newmap, trigger.old, trigger.oldmap, donationsToUpdate);

ItemCalculator.calculateHighestBidForItems(trigger.isDelete, trigger.isInsert, 
                                           trigger.isUpdate, trigger.isUndelete, trigger.new, trigger.newmap, trigger.old, trigger.oldmap, itemsToUpdate);

if(itemsToUpdate.size()>0) update itemsToUpdate.values();
if(donationsToUpdate.size()>0) update donationsToUpdate.values();

}
/*
Set<Id> itemIds = new Set<Id>();
Set<Id> donationIds = new Set<Id>();

if(Trigger.isInsert || Trigger.isUndelete){

for(Bid__c bid : Trigger.New){

    if(bid.Item__c != NULL){
        itemIds.add(bid.Item__c);
    }
    if(bid.Donation__c != NULL){
        donationIds.add(bid.Donation__c);
    }

}

}
else if(Trigger.isUpdate){
    
    for(Bid__c bid : Trigger.New){

        if(bid.Item__c != NULL){
            itemIds.add(bid.Item__c);
        }
        if(bid.Donation__c != NULL){
            donationIds.add(bid.Donation__c);
        }
    
        if(bid.Donation__c != Trigger.oldMap.get(bid.Id).Donation__c && Trigger.oldMap.get(bid.Id).Donation__c != NULL){
            donationIds.add(Trigger.oldMap.get(bid.Id).Donation__c);
        }
    
    //Checking if Item lookup has changed
        if(bid.Item__c != Trigger.oldMap.get(bid.Id).Item__c && Trigger.oldMap.get(bid.Id).Item__c != NULL){

            itemIds.add(Trigger.oldMap.get(bid.Id).Item__c);
        }
    }

}
else if(Trigger.isDelete){

for(Bid__c bid: Trigger.Old){
    if(bid.Item__c != NULL){
        itemIds.add(bid.Item__c);
    }
    if(bid.Donation__c != NULL){
        donationIds.add(bid.Donation__c);
    }
}

}
system.debug('itemIds size: ' + itemIds.size());
system.debug('donationIds size: ' + donationIds.size());


ItemCalculator.calculateHighestBidForItems(itemIds);
DonationCalculator.calculateTotalDonation(donationIds);

}

*/