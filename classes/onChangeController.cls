public class onChangeController{

public class BidWrapper{

public Bid__c bid{get;set;}
public Integer index{get;set;}

public BidWrapper(Bid__c bid, Integer i){
this.bid = bid;
index = i;
}
}

/*public string testString{get;set;}
public String testInput{get;set;}*/
public List<BidWrapper> bids{get;set;}
public Decimal bidIndex{get;set;}

public onChangeController(){
bidIndex = 0;

bids = new List<BidWrapper>();
bids.add(new BidWrapper(new Bid__c(Amount__c = 0.00, Item__c = 'a027A0000024NDX'), 1));
bids.add(new BidWrapper(new Bid__c(Amount__c = 0.00, Item__c = 'a027A0000024WDM'), 2));
bids.add(new BidWrapper(new Bid__c(Amount__c = 0.00, Item__c = 'a027A0000024Moz'), 3));
bids.add(new BidWrapper(new Bid__c(Amount__c = 0.00, Item__c = 'a027A0000024WDH'), 4));

}
public void dummyAction(){

//system.debug('current bid has amount: ' + bidAmount);


}

public void submit(){

system.debug('bidIndex: ' + bidIndex);
}

}