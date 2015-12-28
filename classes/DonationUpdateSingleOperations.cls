//Test class for update logic
//Separate methods for single and bulk tests should be written to validate functionality
//Single methods are as important as bulk methods
@isTest
public class DonationUpdateSingleOperations{
    

public static testmethod void donationTotalTest(){

    List<Contact> donors = TestDataGenerator.CreateDonors(1);
    insert donors;
    List<Donation__c> donations = TestDataGenerator.CreateDonations(donors);
    insert donations;
    List<Item__c> items = TestDataGenerator.CreateItems(2000, 4);
    insert items;
    List<Bid__c> bids = TestDataGenerator.CreateBids(donations, items, 4, donations.size(), items.size(), TRUE);
    
    system.debug('Serialized output: ' + TestDataGenerator.SerializeObjects(donors, donations, items, bids));

    Test.startTest();
    insert bids;
    Test.stopTest();

    //Query Bids to get total
    Decimal bidTotal = (Decimal)[SELECT SUM(Amount__c) bidTotal FROM Bid__c].get(0).get('bidTotal');
    //Query Donation to get total
    Decimal donationTotal = [SELECT Total_Donation__c FROM Donation__c WHERE Id =: donations.get(0).Id].Total_Donation__c;
    system.assert(donationTotal == bidTotal);

}

public static testmethod void itemHighestBidTest1(){

    //Create the First set of Donations and Bids
    List<Contact> donors = TestDataGenerator.CreateDonors(1);
    insert donors;
    List<Donation__c> donations = TestDataGenerator.CreateDonations(donors);
    insert donations;
    List<Item__c> items = TestDataGenerator.CreateItems(2000, 4);
    insert items;
    List<Bid__c> bidList1 = TestDataGenerator.CreateBids(donations, items, 4, donations.size(), items.size(), TRUE);
    
    system.debug('Serialized output: ' + TestDataGenerator.SerializeObjects(donors, donations, items, bidList1));

    //Create the second set of Donations and Bids
    donors = new List<Contact>();
    donors = TestDataGenerator.CreateDonors(1);
    insert donors;
    donations = new List<Donation__c>();
    donations = TestDataGenerator.CreateDonations(donors);
    insert donations;
    List<Bid__c> bidList2 = TestDataGenerator.CreateBids(donations, items, 4, donations.size(), items.size(), TRUE);

    system.debug('Serialized output: ' + TestDataGenerator.SerializeObjects(donors, donations, items, bidList2));

    Test.startTest();
    //Database.InsertResult[] resultList = Database.insert(bids, false);
    insert bidList1;
    insert bidList2;
    Test.stopTest();

    //Those Bids that were inserted in the second Donation had a higher amount and hence their Amount should reflect
    //on the Item
    //Query All items
    items = new List<Item__c>();
    items = [SELECT Highest_Bid__c FROM Item__c];

    system.debug('items: ' + items);

    Integer itemCounter = 0;
    //Validate that the Items' Highest Bids match those of bidList2
    for(Item__c item : items){
        system.assert(item.Highest_Bid__c == bidList2.get(itemCounter).Amount__c);
        itemCounter++;
    }

}

//KK: May make sense to keep the variable values, ie, 4 or 2000 as either static finals or custom settings
public static testmethod void itemHighestBidTest2(){

    List<Contact> donors = TestDataGenerator.CreateDonors(2);
    insert donors;
    List<Donation__c> donations = TestDataGenerator.CreateDonations(donors);
    insert donations;
    List<Item__c> items = TestDataGenerator.CreateItems(2000, 4);
    insert items;
    List<Bid__c> bidList = TestDataGenerator.CreateBids(donations, items, 4, donations.size(), items.size(), TRUE);

    List<Contact> competingDonor = TestDataGenerator.CreateDonors(1);
    insert competingDonor;
    List<Donation__c> competingDonation = TestDataGenerator.CreateDonations(competingDonor);
    insert competingDonation;

    List<Bid__c> compBidList = TestDataGenerator.CreateCompetingBids(competingDonation, items, 4, competingDonation.size(), items.size());

    bidList.addAll(compBidList);

    system.debug('Serialized output: ' + TestDataGenerator.SerializeObjects(donors, donations, items, bidList));

    //Those Bids that were inserted in the first Donation had lower amounts than the second Donation's Bids for the same item
    //and hence they wil fail 
    //Also, the 3rd Donation had the same Bid Amounts as the second bid - hence, they too will fail
    try{
    Test.startTest();
    insert bidList;
    Test.stopTest();
    }
    catch(System.DmlException ex){
        system.debug('num errors: ' + ex.getNumDml());

        System.assert(ex.getNumDml() == 8);

         for (Integer i = 0; i < 4; i++) {
            // Process exception here
            System.assert(ex.getDmlIndex(i) == i);
          }
          for(Integer i = 4; i < 8;  i++){
            System.assert(ex.getDmlIndex(i) == (i+4));
          }

          System.assert(ex.getMessage().contains(System.Label.BidError));
    }
  
}

}