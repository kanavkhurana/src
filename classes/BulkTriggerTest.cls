@isTest
public class BulkTriggerTest{

static testmethod void TestBulkTrigger(){

//Create 400 bid records
List<Bid__c> bids = new List<Bid__c>();
for(Integer i = 0 ; i < 400; i ++){

bids.add(new Bid__c(Amount__c = 1000 * i));

}

insert bids;
}

}