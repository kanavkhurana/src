//KK: Any recursion cases that need to be checked?

trigger BidTrigger on Bid__c (after insert, after update, after delete, after undelete) {

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
    
    //KK: To check if Donation lookup has changed? To avoid One donation having more than one bids for the same item?
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