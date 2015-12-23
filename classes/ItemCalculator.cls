//KK: Any additional error handling to be done?

public class ItemCalculator{

    public static void calculateHighestBidForItems(Boolean isDelete, Boolean isInsert,
      Boolean isUpdate, Boolean isUndelete, List<Bid__c> newList, Map<Id, Bid__c> newMap, 
      List<Bid__c> oldList, Map<Id, Bid__c> oldMap, Map<Id, Item__c> itemsToUpdate){


        Set<Id> itemIds = new Set<Id>();

        if(isInsert || isUndelete){

            for(Bid__c newBid : newList){

                if(newBid.Item__c != NULL){
                    itemIds.add(newBid.Item__c);
                }
            }

        }
        else if(isUpdate){

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

            for(Bid__c oldBid: oldList){
                if(oldBid.Item__c != NULL){
                    itemIds.add(oldBid.Item__c);
                }
            }

        }
        system.debug('itemIds size: ' + itemIds.size());
    //system.debug('donationIds size: ' + donationIds.size());
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

    //List<Item__c> itemsToUpdate = new List<Item__c>();

        for(Id itemId : itemHighestBidInitialMap.keySet()){
            itemsToUpdate.put(itemId, new Item__c(Id = itemId, Highest_Bid__c = itemHighestBidInitialMap.get(itemId)));

        }

    }
}