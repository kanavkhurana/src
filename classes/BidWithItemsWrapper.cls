public class BidWithItemsWrapper implements Comparable{

    public Bid__c bid{ get; set; }
    public Item__c item { get; set;}
    //public Integer index{get;set;}

    public BidWithItemsWrapper(Bid__c b, Item__c i){
        if(b.Amount__c == NULL){
            b.Amount__c = 0.00;
        }
        bid = b;
        item = i;
        //this.index = index;
       
    }

    // Compare opportunities based on the opportunity amount.
    public Integer compareTo(Object compareTo) {
        // Cast argument to BidWithItemsWrapper
        BidWithItemsWrapper compareToBWI = (BidWithItemsWrapper)compareTo;
        
        // The return value of 0 indicates that both elements are equal.
        Integer returnValue = 0;
        if (item.Minimum_Bid__c > compareToBWI.item.Minimum_Bid__c) {
            // Set return value to a positive value.
            returnValue = 1;
        } else if (item.Minimum_Bid__c < compareToBWI.item.Minimum_Bid__c) {
            // Set return value to a negative value.
            returnValue = -1;
        }
        
        return returnValue;       
    }

}