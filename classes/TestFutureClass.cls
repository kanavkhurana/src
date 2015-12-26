public class TestFutureClass{

@Future
public static void TestFutureMethod(){

database.update(new Donation__c(Id = 'a017A0000024TLQ', Status__c = 'Bidding Complete'), false);
database.update(new Item__c(Id = 'a027A0000024MpJQAU', Category__c = 'Sports'),false);

}

}