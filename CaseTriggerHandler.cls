public class CaseTriggerHandler {
    
    public static void beforeInsert(List<Case> lstCase){
        restrictCaseCreation(lstCase);
    }
    
    public static void afterInsert(List<Case> lstCase){
        
    }
    public static void afterUpdate(List<Case> lstCase){
        caseCreationInOrder(lstCase);
    }
    
    public static void caseCreationInOrder(List<Case> lstCase){
        
        list<case> lstOfChildCasees = new list<case>();
        list<case> lstOfCreatedCasees = new list<case>();
        Integer totalChildCases;
        // Sprint 21 : get custom metadata with getAll
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
                    objChildCase.ParentId= each.ParentId;
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
        Set<String> parentId = new Set<String>(); List<Case> lstChildCases = new List<Case>();
        for(Case c: lstCase){
            System.debug('c.Status-1---'+c.Status);
            if(c.Status != 'Closed – Successfully' && c.ParentId != null && c.Parent_Case_Status__c == 'New'){
                System.debug('c.Status--'+c.Status);
                //parentId.add(c.ParentId);
                c.addError('You are not allowed to create a new Case until the predecessor ones are Closed – Successfully');
            }
        }
        
        if(parentId.size() > 0){
            lstChildCases =[Select Id,Status,ParentId from Case where ParentId IN: parentId AND ParentId != null];
            for(Case cc: lstChildCases){
                if(cc.Status != 'Closed – Successfully'){
                    System.debug('c.Status-2-'+cc.Status);
                    cc.addError('You are not allowed to create a new Case until the predecessor ones are Closed – Successfully');
                }
            }
        }
    }
    
    
}