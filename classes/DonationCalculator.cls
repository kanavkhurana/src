public class DonationCalculator{


public static void calculateTotalDonation(Set<Id> donationIds){

        //Initialize a Map for all items in itemIds with Highest Bid = 0 
        Map<Id, Decimal> donationTotalZeroMap = new Map<Id, Decimal>();
        Map<Id, Decimal> donationTotalMap = new Map<Id, Decimal>();

        for(Id donationId : donationIds){
            donationTotalZeroMap.put(donationId, 0);
        }

        List<AggregateResult> donationARList = [SELECT Donation__c, SUM(Amount__c) totalDonation FROM Bid__c WHERE Donation__c IN: donationIds GROUP BY Donation__c];
        system.debug('donationARList: ' + donationARList);

        //Create a map from the donationARList
        for(AggregateResult donationAR : donationARList){
            donationTotalMap.put((Id)donationAR.get('Donation__c'), (Decimal)donationAR.get('totalDonation'));
        }

        donationTotalZeroMap.putAll(donationTotalMap);

        List<Donation__c> donationsToUpdate = new List<Donation__c>();

        for(Id donationId : donationTotalZeroMap.keySet()){
            donationsToUpdate.add(new Donation__c(Id = donationId, Total_Donation__c = donationTotalZeroMap.get(donationId)));

        }

        //KK: Any additional error handling to be done?
        update donationsToUpdate;

}

}