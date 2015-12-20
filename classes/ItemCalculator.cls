public class ItemCalculator{

    public static void calculateHighestBidForItems(Set<Id> itemIds){

        //Initialize a Map for all items in itemIds with Highest Bid = 0 
        Map<Id, Decimal> itemHighestBidZeroMap = new Map<Id, Decimal>();
        Map<Id, Decimal> itemHighestBidMap = new Map<Id, Decimal>();

        for(Id itemId : itemIds){
            itemHighestBidZeroMap.put(itemId, 0);
        }

        List<AggregateResult> itemARList = [SELECT Item__c, MAX(Amount__c) highestBid FROM Bid__c WHERE Item__c IN: itemIds GROUP BY Item__c];
        system.debug('itemARList: ' + itemARList);

        //Create a map from the itemARList
        for(AggregateResult itemAR : itemARList){
            itemHighestBidMap.put((Id)itemAR.get('Item__c'), (Decimal)itemAR.get('highestBid'));
        }

        itemHighestBidZeroMap.putAll(itemHighestBidMap);

        List<Item__c> itemsToUpdate = new List<Item__c>();

        for(Id itemId : itemHighestBidZeroMap.keySet()){
            itemsToUpdate.add(new Item__c(Id = itemId, Highest_Bid__c = itemHighestBidZeroMap.get(itemId)));

        }

        //KK: Any additional error handling to be done?
        update itemsToUpdate;

    }
}