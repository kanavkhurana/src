global class CustomIterable implements Iterator<list<BidWithItemsWrapper>>
{ 
   //KK: Any consideration to be given to security, ie, public, private, etc?
   public list<BidWithItemsWrapper> ItemList{get; set;}
   public list<BidWithItemsWrapper> ItemListComplete{get;set;}
   
   list<BidWithItemsWrapper> ItemListRequested{get; set;}
  public Map< String, List<BidWithItemsWrapper>> categoryItemMap{get;set;}
   Integer pointer {get; set;} 
   Integer setPageSize {get; set;} 
   Integer totalNumberOfPages{get;set;}
   Integer currentPage{get;set;}

   public CustomIterable(List<BidWithItemsWrapper> lstAccWr)
   {
       ItemList = new list<BidWithItemsWrapper >(); 
       ItemListRequested = new list<BidWithItemsWrapper >();   
       ItemListComplete = new List<BidWithItemsWrapper>();
       categoryItemMap = new Map<String, List<BidWithItemsWrapper>>();
       
       ItemList = lstAccWr;
       ItemListComplete = ItemList;
       //Integer index = 1;

       //Create Category Map
       for(BidWithItemsWrapper bwi : itemList )
        {
            //bwi.index = index++;
            //itemCategories.add(item.Category__c);
            if(categoryItemMap.containsKey(bwi.Item.Category__c)){
                List<BidWithItemsWrapper> bwiListForACategory = categoryItemMap.get(bwi.item.Category__c);
                bwiListForACategory.add(bwi);
                categoryItemMap.put(bwi.item.Category__c, bwiListForACategory);

            }
            else{
                List<BidWithItemsWrapper> bwiListForACategory = new List<BidWithItemsWrapper>();
                bwiListForACategory.add(bwi);
                categoryItemMap.put(bwi.item.Category__c, bwiListForACategory);
            }
        }

       system.debug('ItemList.Size() = ' + ItemList.size());
       setPageSize = 5;
       pointer = 0;  
       
       totalNumberOfPages = Integer.valueOf(Math.ceil( (Decimal) ItemList.size() / (Decimal) setPageSize ));
       currentPage = 1;
   }   

    
  public void recalculateTotalNumberOfPages(){

      totalNumberOfPages = Integer.valueOf(Math.ceil( (Decimal) ItemList.size() / (Decimal) setPageSize ));
  
  }
   global boolean isNotFirst(){     
       system.debug('isNotFirst() was called!');
       
       if(currentPage == 1) {
           return false; 
       } else {
           return true; 
       }
     
   }   

   //KK: What if hasPrevious() is called before hasNext()?
   global boolean hasPrevious(){     
       system.debug('hasPrevious() was called!');
       system.debug('I am in hasPrevious ' + pointer);
       if(pointer <= setPageSize) {
           return false; 
       } else {
           return true; 
       }
   }   

   
   global boolean hasNext(){ 
       system.debug('hasNext() was called!');
       if(pointer >= ItemList.size()) {
           return false; 
       } else {
           return true; 
       }
   } 

   global boolean isNotLast(){     
       system.debug('isNotLast() was called!');
       
       if(currentPage == totalNumberOfPages) {
           return false; 
       } else {
           return true; 
       }
       
   }  
   
      public list<BidWithItemsWrapper> first(){       
      
      ItemListRequested = new list<BidWithItemsWrapper >(); 
      Integer size = ItemList.size();
      
      if(size <= setPageSize){
        pointer = size;
      }
      else{
        pointer = setPageSize;
      }

      for(integer start = 0; start < pointer; ++start)
       {
           ItemListRequested.add(ItemList[start]);
       } 
        //Update currentPage
        currentPage = 1;
        
        return ItemListRequested;

      }

public list<BidWithItemsWrapper > previous(){      
       ItemListRequested = new list<BidWithItemsWrapper >(); 
       system.debug('pointer value is previous before =====' + pointer);
       integer size = ItemList.size(); 
       if(pointer == size)
       {
           if(math.mod(size, setPageSize) > 0)
           {    
               pointer = size - math.mod(size, setPageSize);
           }
           else
           {
               pointer = (size - setPageSize);
           } 
       }
       else
       {
           pointer = (pointer - setPageSize);
       }
       
       system.debug('pointer value is previous =====' + pointer);
       system.debug('pointer value is 2previous ==== ' + (pointer - setPageSize));
       
       for(integer start = (pointer - setPageSize); start < pointer; ++start)
       {
           ItemListRequested.add(ItemList[start]);
       } 
       //Update currentPage
        currentPage = (Math.mod(pointer, setPageSize) == 0) ? (pointer / setPageSize) : ((pointer / setPageSize) + 1);

       return ItemListRequested;
   }  
 
   public list<BidWithItemsWrapper> next(){       
       system.debug('pointer value is ' + pointer);
       system.debug('set page size is ' + setPageSize);
       
       ItemListRequested = new list<BidWithItemsWrapper >(); 
       Integer startNumber;
       Integer size = ItemList.size(); 

       if(hasNext())
       {  
           if(size <= (pointer + setPageSize))
           {
               startNumber = pointer;
               pointer = size;
           }
           else
           {
               pointer = (pointer + setPageSize);
               startNumber = (pointer - setPageSize);
           }
           
           system.debug('pointer value is =====' + pointer);
           system.debug('pointer value is 2==== ' + (pointer - setPageSize));
           
           for(integer start = startNumber; start < pointer; start++)
           {
               ItemListRequested.add(ItemList[start]);
           }
       } 
       //Update currentPage
       currentPage = (Math.mod(pointer, setPageSize) == 0) ? (pointer / setPageSize) : ((pointer / setPageSize) + 1);

       return ItemListRequested;
   } 
  
      public list<BidWithItemsWrapper> last(){       
      
        ItemListRequested = new list<BidWithItemsWrapper >(); 
        Integer size = ItemList.size(); 
        pointer = size;

        for(integer start = setPageSize * (totalNumberOfPages - 1); start < pointer; start++)
           {
               ItemListRequested.add(ItemList[start]);
           }

        //Update currentPage
        currentPage = totalNumberOfPages;

        return ItemListRequested;

      }
    
      public Integer getCurrentPage(){
        return this.currentPage;
      }
      public Integer getTotalNumberOfPages(){
        return this.totalNumberOfPages;
      }
    public void filterList(String filter){       
       
       system.debug('selected filter: ' + filter);
       system.debug('categoryItemMap: ' + categoryItemMap);
       if(filter == System.Label.AllCategories){
       ItemList = ItemListComplete;
       
       }
       else{
       
       ItemList = categoryItemMap.get(filter);
       
       }
       system.debug('New Item List:' + ItemList);
       system.debug('categoryItemMap: ' + categoryItemMap);
       system.debug('ItemListComplete: ' + ItemListComplete);
        
       //Reset the Pointer 
       pointer = 0;
   } 
}