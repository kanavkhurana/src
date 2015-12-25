//KK: Any additional error handling to be done?
public class BidManager{

    public static Map<Id, Decimal> itemIdHighestBidMap;
    
    public static void dispatcher(Boolean isDelete, Boolean isInsert,
      Boolean isUpdate, Boolean isUndelete, Boolean isBefore, Boolean isAfter, List<Bid__c> newList, Map<Id, Bid__c> newMap, 
      List<Bid__c> oldList, Map<Id, Bid__c> oldMap, Map<Id, Donation__c> donationsToUpdate, Map<Id, Item__c> itemsToUpdate){

        if(isBefore){

            system.debug('in a before trigger');

            if(AvoidRecursion.isBeforeFirstRun())// || AvoidRecursion.isAfterFirstRun())
            {
                calculateHighestBidForItems(isDelete, isInsert,
                  isUpdate, isUndelete, isBefore, isAfter, newList, newMap, 
                  oldList, oldMap, itemsToUpdate);

                //calculateTotalDonation(isDelete, isInsert,
                //  isUpdate, isUndelete, isBefore, isAfter, newList, newMap, 
                //  oldList, oldMap, donationsToUpdate);
            }
        }
        else{
            system.debug('in an after trigger');

            if(AvoidRecursion.isAfterFirstRun())
            {
                calculateHighestBidForItems(isDelete, isInsert,
                  isUpdate, isUndelete, isBefore, isAfter,newList,newMap, 
                  oldList,oldMap,itemsToUpdate);

                calculateTotalDonation(isDelete, isInsert,
                  isUpdate, isUndelete, isBefore, isAfter, newList, newMap, 
                  oldList, oldMap, donationsToUpdate);
            }

        }
    }

    public static void calculateHighestBidForItems(Boolean isDelete, Boolean isInsert,
      Boolean isUpdate, Boolean isUndelete, Boolean isBefore, Boolean isAfter, List<Bid__c> newList, Map<Id, Bid__c> newMap, 
      List<Bid__c> oldList, Map<Id, Bid__c> oldMap, Map<Id, Item__c> itemsToUpdate){

        if(isBefore && isInsert){
           system.debug('executing a before insert');

           Set<Id> itemIds = new Set<Id>();
           Set<Id> itemIdsAlreadyCovered = new Set<Id>();

           //Loop and get list of all items
           for(Bid__c newBid : newList){
            itemIds.add(newBid.Item__c);
        }

           //Query list of items
        Map<Id, Item__c> matchingItems = new Map<Id, Item__c>([SELECT Minimum_Bid__c, Highest_Bid__c
          FROM Item__c
          WHERE Id IN: itemIds]);
        itemIdHighestBidMap = new Map<Id, Decimal>();

        //loop 1 and create map of itemid > highest bid (integer)
        for(Bid__c newBid : newList)
        {

            //Check if the bid for the current Item is greater than Max of Minimum Bid and Highest Bid
            Decimal itemMinimumBid = matchingItems.get(newBid.Item__c).Minimum_Bid__c;
            Decimal itemHighestBid = matchingItems.get(newBid.Item__c).Highest_Bid__c;
            Decimal highestBidForItem = 0.00;
            if(itemIdHighestBidMap.containsKey(newBid.Item__c)){
             highestBidForItem = itemIdHighestBidMap.get(newBid.Item__c);
         }

         if(newBid.Amount__c > Math.max(itemMinimumBid, Math.max(itemHighestBid, highestBidForItem)))
         {
            itemIdHighestBidMap.put(newBid.Item__c, newBid.Amount__c);
        }

    }

    for(Bid__c newBid : newList){

        if(itemIdHighestBidMap.containsKey(newBid.Item__c)){
            if(newBid.Amount__c < itemIdHighestBidMap.get(newBid.Item__c)){
                newBid.addError('You must bid higher than the item\'s highest Bid.');
            }
            else if(newBid.Amount__c == itemIdHighestBidMap.get(newBid.Item__c)){
                
                //Check if already covered same bid amount before
                if(itemIdsAlreadyCovered.contains(newBid.Item__c)){
                    newBid.addError('You must bid higher than the item\'s highest Bid.');
                }
                else{
                    itemIdsAlreadyCovered.add(newBid.Item__c);
                }
            }
        }
    }
}
else if(isAfter && isInsert){
    system.debug('executing an after insert');

   for(Id itemId : itemIdHighestBidMap.keySet()){
    itemsToUpdate.put(itemId, new Item__c(Id = itemId, Highest_Bid__c = itemIdHighestBidMap.get(itemId)));
}

}

//Called for update, delete and undelete
else{

    Set<Id> itemIds = new Set<Id>();

    if(isUndelete){
        system.debug('executing an undelete');

        for(Bid__c newBid : newList){

            if(newBid.Item__c != NULL){
                itemIds.add(newBid.Item__c);
            }
        }

    }
    else if(isUpdate){

        system.debug('executing an update');

        for(Bid__c newBid : newList){

            Bid__c oldBid = oldMap.get(newBid.Id);

            //Checking if Item lookup has changed
            if(newBid.Item__c != oldBid.Item__c){

                if(oldBid.Item__c != NULL){
                    itemIds.add(oldBid.Item__c);
                }
                if(newBid.Item__c != NULL){
                    itemIds.add(newBid.Item__c);
                }
            }
            //Checking if Amount has changed
            else if(newBid.Amount__c != oldBid.Amount__c){
                itemIds.add(newBid.Item__c);

            }
        }
    }
    else if(isDelete){

        system.debug('executing a delete');
        for(Bid__c oldBid: oldList){
            if(oldBid.Item__c != NULL){
                itemIds.add(oldBid.Item__c);
            }
        }

    }
    system.debug('itemIds size: ' + itemIds.size());
    
    //Initialize a Map for all items in itemIds with Highest Bid = 0 
    Map<Id, Decimal> itemHighestBidInitialMap = new Map<Id, Decimal>();
    Map<Id, Decimal> itemHighestBidMap = new Map<Id, Decimal>();

    for(Id itemId : itemIds){
        itemHighestBidInitialMap.put(itemId, 0);
    }

    List<AggregateResult> itemARList = [SELECT Item__c, MAX(Amount__c) highestBid FROM Bid__c WHERE Item__c IN: itemIds GROUP BY Item__c];
    system.debug('itemARList: ' + itemARList);

    //Create a map from the itemARList
    for(AggregateResult itemAR : itemARList){
        itemHighestBidMap.put((Id)itemAR.get('Item__c'), (Decimal)itemAR.get('highestBid'));
    }

    itemHighestBidInitialMap.putAll(itemHighestBidMap);

    for(Id itemId : itemHighestBidInitialMap.keySet()){
        itemsToUpdate.put(itemId, new Item__c(Id = itemId, Highest_Bid__c = itemHighestBidInitialMap.get(itemId)));
    }

    if(itemsToUpdate.size()>0) update itemsToUpdate.values();

}
}

public static void calculateTotalDonation(Boolean isDelete, Boolean isInsert,
  Boolean isUpdate, Boolean isUndelete, Boolean isBefore, Boolean isAfter, List<Bid__c> newList, Map<Id, Bid__c> newMap, 
  List<Bid__c> oldList, Map<Id, Bid__c> oldMap, Map<Id, Donation__c> donationsToUpdate){

    Set<Id> donationIds = new Set<Id>();

    if(isInsert || isUndelete){

        system.debug('executing insert or undelete');
        for(Bid__c newBid : newList){

            if(newBid.Donation__c != NULL){
                donationIds.add(newBid.Donation__c);
            }
        }
    }
    else if(isUpdate){

        system.debug('executing an update');

        for(Bid__c newBid : newList){

                Bid__c oldBid = oldMap.get(newBid.Id);

                //Checking if Donation lookup has changed
                if(newBid.Donation__c != oldBid.Donation__c){
                    if(oldBid.Donation__c != NULL){
                        donationIds.add(oldBid.Donation__c);
                    }
                    if(newBid.Donation__c != NULL){
                        donationIds.add(newBid.Donation__c);
                    }
                }
                //Checking if Amount has changed
                else if(newBid.Amount__c != oldBid.Amount__c){
                    donationIds.add(newBid.Donation__c);
                }
            }
        }
        else if(isDelete){

            system.debug('executing a delete');

            for(Bid__c oldBid: oldList){

                if(oldBid.Donation__c != NULL){
                    donationIds.add(oldBid.Donation__c);
                }
            }

        }
        system.debug('donationIds size: ' + donationIds.size());
        
        //Initialize a Map for all items in itemIds with Highest Bid = 0 
        Map<Id, Decimal> donationTotalInitialMap = new Map<Id, Decimal>();
        Map<Id, Decimal> donationTotalMap = new Map<Id, Decimal>();

        for(Id donationId : donationIds){
            donationTotalInitialMap.put(donationId, 0);
        }

        List<AggregateResult> donationARList = [SELECT Donation__c, SUM(Amount__c) totalDonation FROM Bid__c WHERE Donation__c IN: donationIds GROUP BY Donation__c];
        system.debug('donationARList: ' + donationARList);

        //Create a map from the donationARList
        for(AggregateResult donationAR : donationARList){
            donationTotalMap.put((Id)donationAR.get('Donation__c'), (Decimal)donationAR.get('totalDonation'));
        }

        donationTotalInitialMap.putAll(donationTotalMap);

        for(Id donationId : donationTotalInitialMap.keySet()){
            donationsToUpdate.put(donationId, new Donation__c(Id = donationId, Total_Donation__c = donationTotalInitialMap.get(donationId)));
        }

        if(donationsToUpdate.size()>0) update donationsToUpdate.values();
    }
}