public class onChangeController{

/*public string testString{get;set;}
public String testInput{get;set;}*/
public List<Bid__c> bids{get;set;}
public Id itemId{get;set;}

public onChangeController(){

bids = new List<Bid__c>();
bids.add(new Bid__c(Amount__c = 0.00, Item__c = 'a027A0000024NDX'));
bids.add(new Bid__c(Amount__c = 0.00, Item__c = 'a027A0000024WDM'));
bids.add(new Bid__c(Amount__c = 0.00, Item__c = 'a027A0000024Moz'));
bids.add(new Bid__c(Amount__c = 0.00, Item__c = 'a027A0000024WDH'));

}
public void onChangeAction(){

system.debug('current bid has item: ' + itemId);


}

}