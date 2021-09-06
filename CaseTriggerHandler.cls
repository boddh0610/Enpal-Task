public class CaseTriggerHandler {
    
    public static void beforeInsert(List<Case> lstCase){
        restrictCaseCreation(lstCase);
    }
    
    public static void afterInsert(List<Case> lstCase){
        
    }
    public static void afterUpdate(List<Case> lstCase, Map< Id, Case> oldMap){
        caseCreationInOrder(lstCase);
        markUnsuccessfully(lstCase, oldMap);
    }
    public static void markUnsuccessfully(List<Case> lstCase, Map< Id, Case> mapOfOld ){
        Set<String> parentIds = new Set<String>();
        
        list<case> lstOfAllRelatedCases = new list<case>();
        for(Case c: lstCase){
            if(c.ParentId != null && c.Status == 'Closed – Unsuccessfully' && c.Status != mapOfOld.get(c.id).Status){
                //c.Status = 'Closed – Unsuccessfully';  
                parentIds.add(c.ParentId);             
            }
        }
        List<Case> lstRelatedCases = [Select id, Status,ParentId from case where ParentId IN:parentIds];
        for(Case cc: lstRelatedCases){
            cc.Status = 'Closed – Unsuccessfully';
            lstOfAllRelatedCases.add(cc);
            System.debug('cc--'+cc);
        }
        if(lstOfAllRelatedCases.size() > 0){
            update lstOfAllRelatedCases;
        }
        
        List<Case> lstParentCase = [Select id, Status,ParentId from case where Id IN:parentIds];
        for(Case cp:lstParentCase){
            cp.Status = 'Closed – Unsuccessfully';
        }
        if(lstParentCase.size() > 0){
            update lstParentCase;
        }
        
    }
    public static void caseCreationInOrder(List<Case> lstCase){
        
        list<case> lstOfChildCasees = new list<case>();
        list<case> lstOfCreatedCasees = new list<case>();
        Integer totalChildCases;
        //get all custom metadata
        Map<String, Order_Of_Tasks__mdt> mapOrderOfTasks = Order_Of_Tasks__mdt.getAll();
        
        Decimal countOrder;
        for(String eachMap : mapOrderOfTasks.keySet()){
            for(case each : lstCase )
            {
                if( each.Order__c != null )
                    countOrder=each.Order__c+1;
                
                if( (each.Status== 'Closed – Successfully') && ( each.Subject =='Fulfillment Parent Case') &&  mapOrderOfTasks.get(eachMap).Order__c ==1 )
                {
                    case objChildCase = new case();
                    objChildCase.ParentId= each.Id;
                    objChildCase.Order__c=mapOrderOfTasks.get(eachMap).Order__c;
                    objChildCase.RecordTypeId =   mapOrderOfTasks.get(eachMap).RecordTypeId__c;
                    lstOfChildCasees.add(objChildCase);
                    
                }
                if( (each.Status== 'Closed – Successfully') && ( each.Subject !='Fulfillment Parent Case') &&  mapOrderOfTasks.get(eachMap).Order__c ==countOrder && countOrder<= 10 )
                {
                    case objChildCase = new case();
                    objChildCase.ParentId= each.ParentId;
                    objChildCase.Order__c=mapOrderOfTasks.get(eachMap).Order__c;
                    objChildCase.RecordTypeId =   mapOrderOfTasks.get(eachMap).RecordTypeId__c;
                    lstOfChildCasees.add(objChildCase);
                }
            }
        }
        if(lstOfChildCasees != null && lstOfChildCasees.size() > 0)
            insert lstOfChildCasees;
    }
    
    public static void restrictCaseCreation(List<Case> lstCase){
        for(Case c: lstCase){
            System.debug('c.Status-1---'+c.Status);
            if(c.Status != 'Closed – Successfully' && c.ParentId != null && c.Parent_Case_Status__c == 'New'){
                System.debug('c.Status--'+c.Status);
                c.addError('You are not allowed to create a new Case until the predecessor ones are Closed – Successfully');
            }
        }
    }
    
    
}
