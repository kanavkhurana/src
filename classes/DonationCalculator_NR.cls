//KK: Any additional error handling to be done?

public class DonationCalculator_NR{


    public static void calculateTotalDonation(Boolean isDelete, Boolean isInsert,
      Boolean isUpdate, Boolean isUndelete, List<Bid__c> newList, Map<Id, Bid__c> newMap, 
      List<Bid__c> oldList, Map<Id, Bid__c> oldMap, Map<Id, Donation__c> donationsToUpdate){

        Set<Id> donationIds = new Set<Id>();

        if(isInsert || isUndelete){

            for(Bid__c newBid : newList){

                if(newBid.Donation__c != NULL){
                    donationIds.add(newBid.Donation__c);
                }

            }

        }
        else if(isUpdate){

    //KK: To check if Donation lookup has changed? To avoid One donation having more than one bids for the same item?
            for(Bid__c newBid : newList){

                //KK: Code segment not reqd?
                /*if(bid.Donation__c != NULL){
                    donationIds.add(bid.Donation__c);
                }*/
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

        //List<Donation__c> donationsToUpdate = new List<Donation__c>();

        for(Id donationId : donationTotalInitialMap.keySet()){
            donationsToUpdate.put(donationId, new Donation__c(Id = donationId, Total_Donation__c = donationTotalInitialMap.get(donationId)));
        }

        //KK: Any additional error handling to be done?
        
        //update donationsToUpdate;

    }

}