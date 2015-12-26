trigger TestTrigger on Bid__c (before insert) {

system.debug('in trigger');

if(AvoidRecursion.triggerCounter == 0){
system.debug('throwing error');
AvoidRecursion.triggerCounter++;
Trigger.New[0].addError('my error');
}

update new Donation__c(Id = 'a017A0000024TLQ', Status__c = 'Bidding Complete');
update new Item__c(Id = 'a027A0000024MpJQAU', Category__c = 'Sports');
        
}