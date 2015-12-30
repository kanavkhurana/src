//KK: Any additional error handling to be done?
public class BidManager{

    public static Map<Id, Decimal> itemIdHighestBidMap;
    public static Boolean errorsFoundInBeforeInsert = FALSE;
    public static Boolean calculateItemIdHighestBidMap = TRUE;

    public static void dispatcher(Boolean isDelete, Boolean isInsert,
      Boolean isUpdate, Boolean isUndelete, Boolean isBefore, Boolean isAfter, List<Bid__c> newList, Map<Id, Bid__c> newMap, 
      List<Bid__c> oldList, Map<Id, Bid__c> oldMap, Map<Id, Donation__c> donationsToUpdate, Map<Id, Item__c> itemsToUpdate)
    {

        //For Deletion error coverage
        if(Test.IsRunningTest() && TestDataGenerator.coverDeletionBlock){
            throw new FakeException('This is a fake exception');
        }
        
        system.debug('running chunk no. ' + AvoidRecursion.triggerCounter++);
        system.debug('static variable errorsFoundInBeforeInsert: ' + errorsFoundInBeforeInsert);
        system.debug('static variable calculateItemIdHighestBidMap: ' + calculateItemIdHighestBidMap);
        
        
        if(newList != null){
            system.debug('Trigger New size: ' + newList.size()); 
        }
        if(oldList != null){
            system.debug('Trigger Old size: ' + oldList.size()); 
        }
        
        system.debug('itemIdHighestBidMap: ' + itemIdHighestBidMap);

        if(isBefore && calculateItemIdHighestBidMap){

            system.debug('in a before trigger');
            system.debug('AvoidRecursion.AlreadyRunning: ' + AvoidRecursion.AlreadyRunning);
            if(!AvoidRecursion.AlreadyRunning)// || AvoidRecursion.isAfterFirstRun())
{
    AvoidRecursion.AlreadyRunning = TRUE;

    calculateHighestBidForItems(isDelete, isInsert,
      isUpdate, isUndelete, isBefore, isAfter, newList, newMap, 
      oldList, oldMap, itemsToUpdate);

    AvoidRecursion.AlreadyRunning = FALSE;
                //calculateTotalDonation(isDelete, isInsert,
                //  isUpdate, isUndelete, isBefore, isAfter, newList, newMap, 
                //  oldList, oldMap, donationsToUpdate);

    if(errorsFoundInBeforeInsert){
        calculateItemIdHighestBidMap = FALSE;
    }
}
}
else if(isAfter){
    system.debug('in an after trigger');
    system.debug('AvoidRecursion.AlreadyRunning: ' + AvoidRecursion.AlreadyRunning);

    if(!AvoidRecursion.AlreadyRunning)
    {
        AvoidRecursion.AlreadyRunning = TRUE;
                //If Item updates fail, the Bid records to be 
        calculateHighestBidForItems(isDelete, isInsert,
          isUpdate, isUndelete, isBefore, isAfter,newList,newMap, 
          oldList,oldMap,itemsToUpdate);

        AvoidRecursion.AlreadyRunning = FALSE;
    }
    system.debug('AvoidRecursion.AlreadyRunning: ' + AvoidRecursion.AlreadyRunning);

    if(!AvoidRecursion.AlreadyRunning){
        AvoidRecursion.AlreadyRunning = TRUE;

        calculateTotalDonation(isDelete, isInsert,
          isUpdate, isUndelete, isBefore, isAfter, newList, newMap, 
          oldList, oldMap, donationsToUpdate);

        AvoidRecursion.AlreadyRunning = FALSE;
    }

//KK: Error condition to be checked for Item
    if(itemsToUpdate.size()>0){
        update itemsToUpdate.values();
    }
//KK: Look at condition when donation DML fails
    if(donationsToUpdate.size()>0){
        update donationsToUpdate.values();
        calculateItemIdHighestBidMap = TRUE;
    }

}

}

public static void calculateHighestBidForItems(Boolean isDelete, Boolean isInsert,
  Boolean isUpdate, Boolean isUndelete, Boolean isBefore, Boolean isAfter, List<Bid__c> newList, Map<Id, Bid__c> newMap, 
  List<Bid__c> oldList, Map<Id, Bid__c> oldMap, Map<Id, Item__c> itemsToUpdate){

    List<Bid__c> errorList = new List<Bid__c>();
    Map<Id, Item__c> matchingItems = new Map<Id, Item__c>();

    if(isBefore && isInsert){
     system.debug('executing a before insert');

     Set<Id> itemIds = new Set<Id>();
     Set<Id> itemIdsAlreadyCovered = new Set<Id>();

           //Loop and get list of all items
     for(Bid__c newBid : newList){
        itemIds.add(newBid.Item__c);
    }

    if(itemIds.size() > 0){
    //Query list of items
        matchingItems = new Map<Id, Item__c>([SELECT Minimum_Bid__c, Highest_Bid__c
          FROM Item__c
          WHERE Id IN: itemIds FOR UPDATE]);
    }

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

         /*if(itemHighestBid == NULL){
            if(newBid.Amount__c > )
        }*/
         //else{
        //if(itemIdHighestBidMap.isEmpty()){
        if(itemHighestBid == 0.00 || itemHighestBid == NULL){
            if(itemIdHighestBidMap.isEmpty()){
                if(newBid.Amount__c >= itemMinimumBid){
                    itemIdHighestBidMap.put(newBid.Item__c, newBid.Amount__c);
                }
            }
            else if(newBid.Amount__c > highestBidForItem){
                itemIdHighestBidMap.put(newBid.Item__c, newBid.Amount__c);
            }
        }
        else if(newBid.Amount__c > Math.max(itemHighestBid, highestBidForItem)) 
        //if(newBid.Amount__c > Math.max(itemMinimumBid, Math.max(itemHighestBid, highestBidForItem)))
        {
            itemIdHighestBidMap.put(newBid.Item__c, newBid.Amount__c);
        }
         //}
    }

    system.debug('itemIdHighestBidMap: ' + itemIdHighestBidMap);


    for(Bid__c newBid : newList){   

        if(itemIdHighestBidMap.containsKey(newBid.Item__c)){
            if(newBid.Amount__c < itemIdHighestBidMap.get(newBid.Item__c)){
                newBid.addError(System.Label.BidError);
                //KK: Can be removed after code is deployable
                errorList.add(newBid);
                errorsFoundInBeforeInsert = TRUE;
            }
            else if(newBid.Amount__c == itemIdHighestBidMap.get(newBid.Item__c)){

                //Check if already covered same bid amount before
                if(itemIdsAlreadyCovered.contains(newBid.Item__c)){
                    newBid.addError(System.Label.BidError);
                    //KK: Can be removed after code is deployable
                    errorList.add(newBid);
                    
                    errorsFoundInBeforeInsert = TRUE;
                }
                else{
                    itemIdsAlreadyCovered.add(newBid.Item__c);
                }
            }
        }
    }
}
else if(isAfter && isInsert){
 if(!errorsFoundInBeforeInsert){
     system.debug('executing an after insert');

     if(itemIdHighestBidMap != NULL){
         system.debug('itemIdHighestBidMap size: ' + itemIdHighestBidMap.size());
     }

     for(Id itemId : itemIdHighestBidMap.keySet()){
        itemsToUpdate.put(itemId, new Item__c(Id = itemId, Highest_Bid__c = itemIdHighestBidMap.get(itemId)));
    }
}
    //else{
    //    errorsFoundInBeforeInsert = FALSE;
    //}
}

//Called for update, delete and undelete
else{
    Set<Id> itemIds = new Set<Id>();

    if(isUndelete){
        system.debug('executing an undelete');

        for(Bid__c newBid : newList){

            if(newBid.Item__c != NULL && newBid.Amount__c != NULL){
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
            if(oldBid.Item__c != NULL && oldBid.Amount__c != NULL){
                itemIds.add(oldBid.Item__c);
            }
        }

    }
    system.debug('itemIds size: ' + itemIds.size());
    
    //Initialize a Map for all items in itemIds with Highest Bid = 0 
    Map<Id, Decimal> itemHighestBidInitialMap = new Map<Id, Decimal>();
    Map<Id, Decimal> itemHighestBidMap = new Map<Id, Decimal>();
    //List<AggregateResult> itemARList = new List<AggregateResult>();
    List<Bid__c> relatedBidList = new List<Bid__c>();

    for(Id itemId : itemIds){
        itemHighestBidInitialMap.put(itemId, 0);
    }

    if(itemIds.size()>0){

    /*itemARList = [SELECT Item__c, MAX(Amount__c) highestBid
                                        FROM Bid__c WHERE
                                        Item__c IN: itemIds
                                        GROUP BY Item__c];
                                        */
                                        relatedBidList = [SELECT Item__c, Amount__c
                                        FROM Bid__c
                                        WHERE Item__c IN: itemIds
                                        FOR UPDATE];

                                    }

    //system.debug('itemARList: ' + itemARList);
                                    system.debug('relatedBidList size: ' + relatedBidList.size());

    //Loop through relatedBidList and Find out Maximum Bid Amount for Each Item
                                    for(Bid__c relatedBid : relatedBidList){
                                        if(itemHighestBidInitialMap.containsKey(relatedBid.Item__c)){
                                            Decimal itemHighestBid = itemHighestBidInitialMap.get(relatedBid.Item__c);
                                            //if(itemHighestBid == NULL){
                                            //    itemHighestBid = 0.00;
                                            //}
                                            if(relatedBid.Amount__c != NULL){
                                                if(relatedBid.Amount__c > itemHighestBid){
                                                    itemHighestBidInitialMap.put(relatedBid.Item__c, relatedBid.Amount__c);
                                                }
                                            }
                                        }
                                    }

    //Create a map from the itemARList
    /*for(AggregateResult itemAR : itemARList){
        itemHighestBidMap.put((Id)itemAR.get('Item__c'), (Decimal)itemAR.get('highestBid'));
    }*/

    //itemHighestBidInitialMap.putAll(itemHighestBidMap);

    for(Id itemId : itemHighestBidInitialMap.keySet()){
        itemsToUpdate.put(itemId, new Item__c(Id = itemId, Highest_Bid__c = itemHighestBidInitialMap.get(itemId)));
    }
}

system.debug('itemsToUpdate.size(): ' + itemsToUpdate.size());
system.debug('itemsToUpdate map: ' + itemsToUpdate);

system.debug('errorList size: ' + errorList.size());

}

public static void calculateTotalDonation(Boolean isDelete, Boolean isInsert,
  Boolean isUpdate, Boolean isUndelete, Boolean isBefore, Boolean isAfter, List<Bid__c> newList, Map<Id, Bid__c> newMap, 
  List<Bid__c> oldList, Map<Id, Bid__c> oldMap, Map<Id, Donation__c> donationsToUpdate){

    Set<Id> donationIds = new Set<Id>();

    if(isInsert){
        if(!errorsFoundInBeforeInsert){
            system.debug('executing insert');
            for(Bid__c newBid : newList){
                if(newBid.Donation__c != NULL && newBid.Amount__c != NULL){
                    donationIds.add(newBid.Donation__c);
                }
            }
        }
        else{
            errorsFoundInBeforeInsert = FALSE;
        }
    }
    else if(isUndelete){

        system.debug('executing undelete');
        for(Bid__c newBid : newList){

            if(newBid.Donation__c != NULL && newBid.Amount__c != NULL){
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

            if(oldBid.Donation__c != NULL && oldBid.Amount__c != NULL){
                donationIds.add(oldBid.Donation__c);
            }
        }

    }
    system.debug('donationIds size: ' + donationIds.size());

        //Initialize a Map for all items in itemIds with Highest Bid = 0 
    Map<Id, Decimal> donationTotalInitialMap = new Map<Id, Decimal>();
    Map<Id, Decimal> donationTotalMap = new Map<Id, Decimal>();
    //List<AggregateResult> donationARList = new List<AggregateResult>();
    List<Bid__c> relatedBidList = new List<Bid__c>();

    for(Id donationId : donationIds){
        donationTotalInitialMap.put(donationId, 0);
    }
    if(donationIds.size() > 0){
    /*donationARList = [SELECT Donation__c, SUM(Amount__c) totalDonation
                                            FROM Bid__c
                                            WHERE Donation__c IN: donationIds
                                            GROUP BY Donation__c FOR UPDATE];
                                            */
                                            relatedBidList = [SELECT Donation__c, Amount__c
                                            FROM Bid__c
                                            WHERE Donation__c IN: donationIds
                                            FOR UPDATE];
                                        }

    //system.debug('donationARList: ' + donationARList);
                                        system.debug('relatedBidList size: ' + relatedBidList.size());

                                        for(Bid__c relatedBid : relatedBidList){
                                            if(donationTotalInitialMap.containsKey(relatedBid.Donation__c)){
                                                Decimal donationTotalBid = donationTotalInitialMap.get(relatedBid.Donation__c);
                                                //if(donationTotalBid == NULL){
                                                //    donationTotalBid = 0.00;
                                                //}
                                                if(relatedBid.Amount__c != NULL){
                                                    donationTotalBid += relatedBid.Amount__c;
                                                }
                                                donationTotalInitialMap.put(relatedBid.Donation__c, donationTotalBid);
                                            }
                                        }
    //Create a map from the donationARList
    //for(AggregateResult donationAR : donationARList){
    //    donationTotalMap.put((Id)donationAR.get('Donation__c'), (Decimal)donationAR.get('totalDonation'));
    //}

    //donationTotalInitialMap.putAll(donationTotalMap);

                                        for(Id donationId : donationTotalInitialMap.keySet()){
                                            donationsToUpdate.put(donationId, new Donation__c(Id = donationId, Total_Donation__c = donationTotalInitialMap.get(donationId)));
                                        }
                                        system.debug('donationsToUpdate map: ' + donationsToUpdate);

                                    }
                                }