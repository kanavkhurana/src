/**
    BidManager : This class handles the various update operations on the 'Item' and 'Donation' objects
    Logic: As per the Document, it was clear that Bids made for any item that were less than or equal to the 
    Item's highest Bid would be rejected. Now let's look at a bulk scenario.
    Eg, Let's say we have an Item, Item 1 with a Highest Bid Value of USD 1000
    Now, let's say that we are uploading multiple Bids for Item 1 with the following values:
    Bid 1 - USD 2000
    Bid 2 - USD 3000
    Bid 3 - USD 4000
    Bid 4 - USD 4000
    Now, should all the 4 bids be allowed? Or should only the Highest Bid from AMONG these 4 be allowed?
    Going as per a real auction - it would seem that Bids 1 and 2 would be invalid, as both of them are less than the
    Highest Bid for the Item in the CURRENT LOT, ie, USD 4000. Also, Bid 4 would be invalid, as it has come AFTER a matching
    highest bid, ie, Bid 3.
    Since it was unclear from the Document what should happen, this is an assumption that I've made for the Update Logic. 
    This has been handled in the code in 2 steps:

    Step 1 - Before Insert trigger
    a. If we take the above example, Bids 1, 2 and 4 need to be stopped from getting inserted. The before insert logic 
    helps by marking these with 'addError'.
    b. The Highest Bids for a particular item are stored in a Static Variable.

    Step 2 - After Insert trigger
    The Highest Bid Map created in Step 1 above is picked and the 'Highest Bid' is updated on the respective 'Item' record

    For all other operations, ie, 'delete', 'update' and 'undelete' - only 'After' trigger contexts are utilised.
    Hence, as such, DML updates to Item and Dontaion are done only in 'After' trigger contexts
*/
public class BidManager{
    
    public static Map<Id, Decimal> itemIdHighestBidMap;
    
    //Static variables used to control Before Insert and After insert functioning
    public static Boolean errorsFoundInBeforeInsert = FALSE;
    public static Boolean calculateItemIdHighestBidMap = TRUE;
    
    /**
        Dispatcher method that is invoked by the trigger. This further calls the 'Item' and 'Donation' update logic methods.
        
        @param isDelete, isInsert, isUpdate, isUndelete, isBefore, isAfter - Trigger context variables
        @param newList, newMap, oldList, oldMap - Trigger context lists and Maps - both old and new
        @param donationsToUpdate, itemsToUpdate - Donations and Items Map that is used for the final DML's
        @returns void
    */
    public static void dispatcher(Boolean isDelete, Boolean isInsert,
                                  Boolean isUpdate, Boolean isUndelete, Boolean isBefore, Boolean isAfter, List<Bid__c> newList, Map<Id, Bid__c> newMap, 
                                  List<Bid__c> oldList, Map<Id, Bid__c> oldMap, Map<Id, Donation__c> donationsToUpdate, Map<Id, Item__c> itemsToUpdate)
    {

        
        //Debug statements
        /******************/
        system.debug('running trigger chunk no. ' + AvoidRecursion.triggerCounter++);
        system.debug('static variable errorsFoundInBeforeInsert: ' + errorsFoundInBeforeInsert);
        system.debug('static variable calculateItemIdHighestBidMap: ' + calculateItemIdHighestBidMap);
        
        if(newList != null){
            system.debug('Trigger New size: ' + newList.size()); 
        }
        if(oldList != null){
            system.debug('Trigger Old size: ' + oldList.size()); 
        }
        
        system.debug('itemIdHighestBidMap: ' + BidManager.itemIdHighestBidMap);
        /******************/
        
        /*
        As per logic explanation given before the class definition, in an insert scenario, both the
        'before' and 'after' events are executed, in this order. However, if there are some records that we mark with
        'addError' in the 'before' event, Salesforce runs the 'before' and 'after' update cycle AGAIN,
        but ONLY FOR the other successful records. In the second cycle, however, we would not want the 'addError' and 
        Highest Bid Map calculation logic to run again, as these would be inconsequential
        The Static variable 'calculateItemIdHighestBidMap' helps achieve this
        */
        //Before trigger block
        if(isBefore && calculateItemIdHighestBidMap){
            
            system.debug('AvoidRecursion.AlreadyRunning: ' + AvoidRecursion.AlreadyRunning);
            
            //Recursion check
            if(!AvoidRecursion.AlreadyRunning)
            {
                AvoidRecursion.AlreadyRunning = TRUE;
                
                //Calling the 'Item' update logic
                calculateHighestBidForItems(isDelete, isInsert,
                                            isUpdate, isUndelete, isBefore, isAfter, newList, newMap, 
                                            oldList, oldMap, itemsToUpdate);
                
                AvoidRecursion.AlreadyRunning = FALSE;
                
                //Reset the Static variable for subsequent triggers to function as expected
                if(errorsFoundInBeforeInsert){
                    calculateItemIdHighestBidMap = FALSE;
                }
            }
        }
        //After trigger block
        else if(isAfter){
            system.debug('AvoidRecursion.AlreadyRunning: ' + AvoidRecursion.AlreadyRunning);
            
            //Recursion check
            if(!AvoidRecursion.AlreadyRunning)
            {
                AvoidRecursion.AlreadyRunning = TRUE;
                calculateHighestBidForItems(isDelete, isInsert,
                                            isUpdate, isUndelete, isBefore, isAfter,newList,newMap, 
                                            oldList,oldMap,itemsToUpdate);
                
                AvoidRecursion.AlreadyRunning = FALSE;
            }
            system.debug('AvoidRecursion.AlreadyRunning: ' + AvoidRecursion.AlreadyRunning);
            
            //Recursion check
            if(!AvoidRecursion.AlreadyRunning){
                AvoidRecursion.AlreadyRunning = TRUE;
                
                calculateTotalDonation(isDelete, isInsert,
                                       isUpdate, isUndelete, isBefore, isAfter, newList, newMap, 
                                       oldList, oldMap, donationsToUpdate);
                
                AvoidRecursion.AlreadyRunning = FALSE;
            }
            
            /*
            All updates to be done only in 'After' triggers, for insert, delete, update and undelete
            */
            //Item update
            if(itemsToUpdate.size()>0){
                update itemsToUpdate.values();
            }
            //Donation update
            if(donationsToUpdate.size()>0){
                update donationsToUpdate.values();
                calculateItemIdHighestBidMap = TRUE;
            }
            
        }
        
    }
    
     /**
        Method that calculates the highest bid value for Items
        
        @param isDelete, isInsert, isUpdate, isUndelete, isBefore, isAfter - Trigger context variables
        @param newList, newMap, oldList, oldMap - Trigger context lists and Maps - both old and new
        @param itemsToUpdate - Item Map that is used for the final DML's
        @returns void
    */
    public static void calculateHighestBidForItems(Boolean isDelete, Boolean isInsert,
                                                   Boolean isUpdate, Boolean isUndelete, Boolean isBefore, Boolean isAfter, List<Bid__c> newList, Map<Id, Bid__c> newMap, 
                                                   List<Bid__c> oldList, Map<Id, Bid__c> oldMap, Map<Id, Item__c> itemsToUpdate){
                                                       
                                                       //Utility list to store Bids marked with 'addError'
                                                       List<Bid__c> errorList = new List<Bid__c>();
                                                       

                                                       //Before insert trigger context
                                                       if(isBefore && isInsert){
                                                           system.debug('executing a before insert');
                                                           
                                                           //Set to get all Item Ids
                                                           Set<Id> itemIds = new Set<Id>();

                                                           //Set to mark duplicate Bids which match the Highest Bid
                                                           //among the Trigger record batch 
                                                           Set<Id> itemIdsAlreadyCovered = new Set<Id>();

                                                           //Loop and get All Item Ids
                                                           for(Bid__c newBid : newList){
                                                               itemIds.add(newBid.Item__c);
                                                           }
                                                           
                                                            Map<Id, Item__c> matchingItems = new Map<Id, Item__c>();

                                                           if(itemIds.size() > 0){
                                                               //Query list of items
                                                               matchingItems = new Map<Id, Item__c>([SELECT Minimum_Bid__c, Highest_Bid__c
                                                                                                     FROM Item__c
                                                                                                     WHERE Id IN: itemIds FOR UPDATE]);
                                                           }
                                                           
                                                           //Initialize the Static Map Variable
                                                           BidManager.itemIdHighestBidMap = new Map<Id, Decimal>();
                                                           
                                                           //Loop 1 : Create map of itemid > highest bid
                                                           for(Bid__c newBid : newList)
                                                           {
                                                               
                                                               //Check if the bid for the current Item is greater than Max of Minimum Bid and Highest Bid
                                                               Decimal itemMinimumBid = matchingItems.get(newBid.Item__c).Minimum_Bid__c;
                                                               Decimal itemHighestBid = matchingItems.get(newBid.Item__c).Highest_Bid__c;
                                                               Decimal highestBidForItemInCurrentLot = 0.00;

                                                               //Get the highest bid for an item from the Current Record Batch
                                                               if(BidManager.itemIdHighestBidMap.containsKey(newBid.Item__c)){
                                                                   highestBidForItemInCurrentLot = BidManager.itemIdHighestBidMap.get(newBid.Item__c);
                                                               }
                                                               
                                                               //If the Item has no Highest Bid 
                                                               if(itemHighestBid == 0.00 || itemHighestBid == NULL){
                                                                   if(BidManager.itemIdHighestBidMap.isEmpty()){
                                                                       //Add Bid Amount to Highest Bid Map if Amount > Minimum Bid
                                                                       if(newBid.Amount__c >= itemMinimumBid){
                                                                           BidManager.itemIdHighestBidMap.put(newBid.Item__c, newBid.Amount__c);
                                                                       }
                                                                   }
                                                                   //Add Bid Amount to Highest Bid Map if Amount > highestBidForItemInCurrentLot
                                                                   else if(newBid.Amount__c > highestBidForItemInCurrentLot){
                                                                       BidManager.itemIdHighestBidMap.put(newBid.Item__c, newBid.Amount__c);
                                                                   }
                                                               }
                                                               //If the Item has a Highest bid
                                                               //Check if the Bid Amount > Item's Highest Bid and highestBidForItemInCurrentLot
                                                               //And Add to Highest Bid Map if so
                                                               else if(newBid.Amount__c > Math.max(itemHighestBid, highestBidForItemInCurrentLot)) 
                                                               {
                                                                   BidManager.itemIdHighestBidMap.put(newBid.Item__c, newBid.Amount__c);
                                                               }
                                                           }
                                                           
                                                           system.debug('itemIdHighestBidMap: ' + BidManager.itemIdHighestBidMap);
                                                           
                                                           
                                                           //Loop 2 : Mark relevant Bids with 'addError'
                                                           for(Bid__c newBid : newList){   
                                                               
                                                               if(BidManager.itemIdHighestBidMap.containsKey(newBid.Item__c)){
                                                                   
                                                                   //If Bid's Amount < Highest Amount for the Item
                                                                   if(newBid.Amount__c < BidManager.itemIdHighestBidMap.get(newBid.Item__c)){
                                                                       newBid.addError(System.Label.HighestBidError);
                                                                       errorList.add(newBid);
                                                                       //Flag a static variable to skip the After Insert logic 
                                                                       errorsFoundInBeforeInsert = TRUE;
                                                                   }
                                                                   //If Bid's Amount = Highest Amount for the Item
                                                                   else if(newBid.Amount__c == BidManager.itemIdHighestBidMap.get(newBid.Item__c)){
                                                                       
                                                                       //If this is NOT the first Bid with the same amount
                                                                       if(itemIdsAlreadyCovered.contains(newBid.Item__c)){
                                                                           newBid.addError(System.Label.HighestBidError);
                                                                           errorList.add(newBid);
                                                                           
                                                                           errorsFoundInBeforeInsert = TRUE;
                                                                       }
                                                                       //Flag that a Highest Bid for an Item has already been covered
                                                                       else{
                                                                           itemIdsAlreadyCovered.add(newBid.Item__c);
                                                                       }
                                                                   }
                                                               }
                                                           }
                                                       }
                                                       //After insert trigger context
                                                       else if(isAfter && isInsert){
                                                           //if NO ERRORS found in Before Insert logic
                                                           if(!errorsFoundInBeforeInsert){
                                                               system.debug('executing an after insert');
                                                               
                                                               if(BidManager.itemIdHighestBidMap != NULL){
                                                                   system.debug('itemIdHighestBidMap size: ' + BidManager.itemIdHighestBidMap.size());
                                                               }
                                                               
                                                               //Loop through Static Map variable and add values to 
                                                               //itemToUpdate Map
                                                               for(Id itemId : BidManager.itemIdHighestBidMap.keySet()){
                                                                   itemsToUpdate.put(itemId, new Item__c(Id = itemId, Highest_Bid__c = BidManager.itemIdHighestBidMap.get(itemId)));
                                                               }
                                                           }
                                                       }
                                                       //After update, delete and undelete trigger contexts
                                                       else{
                                                           //Capturing item Ids to Update
                                                           Set<Id> itemIds = new Set<Id>();
                                                           
                                                           //After Undelete trigger context
                                                           if(isUndelete){
                                                               system.debug('executing an undelete');
                                                               
                                                               for(Bid__c newBid : newList){
                                                                   
                                                                   if(newBid.Item__c != NULL && newBid.Amount__c != NULL){
                                                                       itemIds.add(newBid.Item__c);
                                                                   }
                                                               }
                                                               
                                                           }
                                                           //After Update trigger context
                                                           else if(isUpdate){
                                                               
                                                               system.debug('executing an update');
                                                               
                                                               for(Bid__c newBid : newList){
                                                                   
                                                                   Bid__c oldBid = oldMap.get(newBid.Id);
                                                                   
                                                                   //Checking if Item lookup has changed
                                                                   if(newBid.Item__c != oldBid.Item__c){
                                                                       
                                                                       //Process old Item
                                                                       if(oldBid.Item__c != NULL){
                                                                           itemIds.add(oldBid.Item__c);
                                                                       }
                                                                       //Process new Item
                                                                       if(newBid.Item__c != NULL){
                                                                           itemIds.add(newBid.Item__c);
                                                                       }
                                                                   }
                                                                   //Checking if Amount has changed
                                                                   else if(newBid.Amount__c != oldBid.Amount__c){
                                                                       itemIds.add(newBid.Item__c);
                                                                       
                                                                   }
                                                               }
                                                           }
                                                           //After Delete trigger context
                                                           else if(isDelete){
                                                               
                                                               system.debug('executing a delete');

                                                               for(Bid__c oldBid: oldList){
                                                                   if(oldBid.Item__c != NULL && oldBid.Amount__c != NULL){
                                                                       itemIds.add(oldBid.Item__c);
                                                                   }
                                                               }
                                                               
                                                           }
                                                           system.debug('itemIds size: ' + itemIds.size());
                                                           
                                                           //Initialize a Map for all items in itemIds with Highest Bid = 0 
                                                           Map<Id, Decimal> itemHighestBidInitialMap = new Map<Id, Decimal>();

                                                           List<Bid__c> relatedBidList = new List<Bid__c>();
                                                           
                                                           for(Id itemId : itemIds){
                                                               itemHighestBidInitialMap.put(itemId, 0);
                                                           }
                                                           
                                                           //Query all related Bids to recalculate each Item's
                                                           //Highest Bid
                                                           if(itemIds.size()>0){
                                                               
                                                               relatedBidList = [SELECT Item__c, Amount__c
                                                                                 FROM Bid__c
                                                                                 WHERE Item__c IN: itemIds
                                                                                 FOR UPDATE]; 
                                                           }
                                                           
                                                           system.debug('relatedBidList size: ' + relatedBidList.size());
                                                           
                                                           //Loop through relatedBidList and Find out Maximum Bid Amount for Each Item
                                                           for(Bid__c relatedBid : relatedBidList){
                                                               if(itemHighestBidInitialMap.containsKey(relatedBid.Item__c)){
                                                                   Decimal itemHighestBid = itemHighestBidInitialMap.get(relatedBid.Item__c);
                                                                   if(relatedBid.Amount__c != NULL){
                                                                       if(relatedBid.Amount__c > itemHighestBid){
                                                                           itemHighestBidInitialMap.put(relatedBid.Item__c, relatedBid.Amount__c);
                                                                       }
                                                                   }
                                                               }
                                                           }
                                                           
                                                           //Populate itemsToUpdate Map
                                                           for(Id itemId : itemHighestBidInitialMap.keySet()){
                                                               //Set the Highest Bid to NULL if there are no Bids
                                                               itemsToUpdate.put(itemId, new Item__c(Id = itemId,
                                                                                                     Highest_Bid__c = itemHighestBidInitialMap.get(itemId) == 0 ? NULL : itemHighestBidInitialMap.get(itemId)
                                                                                                     ));

                                                           }
                                                       }
                                                       
                                                       system.debug('itemsToUpdate.size(): ' + itemsToUpdate.size());
                                                       system.debug('errorList size: ' + errorList.size());
                                                       
                                                   }

      /**
        Method that calculates the Total Donation value for Donations
        
        @param isDelete, isInsert, isUpdate, isUndelete, isBefore, isAfter - Trigger context variables
        @param newList, newMap, oldList, oldMap - Trigger context lists and Maps - both old and new
        @param donationsToUpdate - Donation Map that is used for the final DML's
        @returns void
    */
    public static void calculateTotalDonation(Boolean isDelete, Boolean isInsert,
                                              Boolean isUpdate, Boolean isUndelete, Boolean isBefore, Boolean isAfter, List<Bid__c> newList, Map<Id, Bid__c> newMap, 
                                              List<Bid__c> oldList, Map<Id, Bid__c> oldMap, Map<Id, Donation__c> donationsToUpdate){
                                                  
                                                  Set<Id> donationIds = new Set<Id>();
                                                  
                                                  //After insert trigger context
                                                  if(isInsert){
                                                      //If no errors Found in Before Insert
                                                      if(!errorsFoundInBeforeInsert){

                                                          system.debug('executing insert');

                                                          for(Bid__c newBid : newList){
                                                              if(newBid.Donation__c != NULL && newBid.Amount__c != NULL){
                                                                  donationIds.add(newBid.Donation__c);
                                                              }
                                                          }
                                                      }
                                                      //Reset the errorsFoundInBeforeInsert Static variable
                                                      //so that subsequent triggers can run as expected
                                                      else{
                                                          errorsFoundInBeforeInsert = FALSE;
                                                      }
                                                  }
                                                  //After undelete trigger context
                                                  else if(isUndelete){
                                                      
                                                      system.debug('executing undelete');
                                                      for(Bid__c newBid : newList){
                                                          
                                                          if(newBid.Donation__c != NULL && newBid.Amount__c != NULL){
                                                              donationIds.add(newBid.Donation__c);
                                                          }
                                                      }
                                                  }
                                                  //After update trigger context
                                                  else if(isUpdate){
                                                      
                                                      system.debug('executing an update');
                                                      
                                                      for(Bid__c newBid : newList){
                                                          
                                                          Bid__c oldBid = oldMap.get(newBid.Id);
                                                          
                                                          //Checking if Donation lookup has changed
                                                          if(newBid.Donation__c != oldBid.Donation__c){
                                                              //Process Old Donation
                                                              if(oldBid.Donation__c != NULL){
                                                                  donationIds.add(oldBid.Donation__c);
                                                              }
                                                              //Process New Donation
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
                                                  //After delete trigger context
                                                  else if(isDelete){
                                                      
                                                      system.debug('executing a delete');
                                                      
                                                      for(Bid__c oldBid: oldList){
                                                          
                                                          if(oldBid.Donation__c != NULL && oldBid.Amount__c != NULL){
                                                              donationIds.add(oldBid.Donation__c);
                                                          }
                                                      }
                                                      
                                                  }
                                                  system.debug('donationIds size: ' + donationIds.size());
                                                  
                                                  //Initialize a Map for all Donations in donationIds with Total Donation = 0 
                                                  Map<Id, Decimal> donationTotalInitialMap = new Map<Id, Decimal>();
                                                  List<Bid__c> relatedBidList = new List<Bid__c>();
                                                  
                                                  for(Id donationId : donationIds){
                                                      donationTotalInitialMap.put(donationId, 0);
                                                  }
                                                  //Fetch related Bids so as to formulate Total Donation
                                                  if(donationIds.size() > 0){
                                                     
                                                      relatedBidList = [SELECT Donation__c, Amount__c
                                                                        FROM Bid__c
                                                                        WHERE Donation__c IN: donationIds
                                                                        FOR UPDATE];
                                                  }
                                                  
                                                  system.debug('relatedBidList size: ' + relatedBidList.size());
                                                  
                                                  //Calculate TOtal Donations for each Donation
                                                  for(Bid__c relatedBid : relatedBidList){
                                                      if(donationTotalInitialMap.containsKey(relatedBid.Donation__c)){
                                                          Decimal donationTotalBid = donationTotalInitialMap.get(relatedBid.Donation__c);
                                                          if(relatedBid.Amount__c != NULL){
                                                              donationTotalBid += relatedBid.Amount__c;
                                                          }
                                                          donationTotalInitialMap.put(relatedBid.Donation__c, donationTotalBid);
                                                      }
                                                  }
                                                  
                                                  //Add values to donationsToUpdate Map
                                                  for(Id donationId : donationTotalInitialMap.keySet()){
                                                      donationsToUpdate.put(donationId, new Donation__c(Id = donationId, Total_Donation__c = donationTotalInitialMap.get(donationId)));
                                                  }
                                                  system.debug('donationsToUpdate map: ' + donationsToUpdate);
                                                  
                                              }
}