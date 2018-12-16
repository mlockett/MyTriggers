/**
* MyTriggers - adapted from TriggerX (2013) by Sebastian Wagner
* Copyright (c) 2018 appero GmbH. All rights reserved.
*
* This work is licensed under the terms of the MIT license.  
* For a copy, see <LICENCE> in this repository or   
* <https://opensource.org/licenses/MIT>.
*
* @created: 8-2018
* @author: info@appero.com
*
* @Description Lightweight Custom Metadata driven Trigger Framework that scales to your needs.
* Provided with <3 by appero.com
*
* YL edits include assigning a class to "All" trigger event
* "All" does not control recursion, and will fire after event-specific Triggers
*/


global virtual class MyTriggers {

    // YL's new event type
    private static final String ALL_EVENTS = 'All';

    global class MyTriggersException extends Exception {
    }

    @TestVisible
    private static List<MyTriggerSetting__mdt> triggerHandlerSettingMocks;

    @TestVisible
    private static SObjectType sObjectTypeMock;

    @TestVisible
    private static String triggerEventMock;

    /**
     * cast records to appropriate SObjectType in implementations
     */
    global SObject[] Records { get; set; }

    /**
     * used instead of constructor since handlers are instantiated with an empty constructor
     * @param  records Array of SObjects. for INSERT & UPDATE Trigger.new otherwise Trigger.old
     * @return         instance
     */
    global virtual MyTriggers doConstruct(SObject[] records) {

        this.Records = records;
        return this;
    }

    //--------------------------------------------------------------
    // implementable Handlers
    //--------------------------------------------------------------

    /**
     * executed to perform BEFORE_INSERT operations
     */
    global virtual void onBeforeInsert() {
    }

    /**
     * executed to perform AFTER_INSERT operations
     */
    global virtual void onAfterInsert() {
    }

    /**
     * executed to perform BEFORE_UPDATE operations
     * @param  triggerOldMap
     */
    global virtual void onBeforeUpdate(Map<Id, SObject> triggerOldMap) {
    }

    /**
     * executed to perform AFTER_UPDATE operations
     * @param  triggerOldMap
     */
    global virtual void onAfterUpdate(Map<Id, SObject> triggerOldMap) {
    }

    /**
     * executed to perform BEFORE_DELETE operations
     */
    global virtual void onBeforeDelete() {
    }

    /**
     * executed to perform AFTER_DELETE operations
     */
    global virtual void onAfterDelete() {
    }

    /**
     * executed to perform AFTER_UNDELETE operations
     */
    global virtual void onAfterUndelete() {
    }

    //--------------------------------------------------------------
    // General Handling
    //--------------------------------------------------------------


    /**
     * Entry point of MyTriggers framework - called from implementations
     */
    global static void run() {

        SObjectType currentSObjectType;
        if (Test.isRunningTest() && sObjectTypeMock != null) {
            currentSObjectType = sObjectTypeMock;
        } else {
            currentSObjectType = Trigger.new != null
                    ? Trigger.new.getSObjectType()
                    : Trigger.old.getSObjectType();
        }

        if (currentSObjectType != executionContextSObjectType) {
            setTriggerHandlerMaps(currentSObjectType);
        }
        executionContextSObjectType = currentSObjectType;

        if (triggerEventsToTriggerHandlers == null || triggerEventsToTriggerHandlers.isEmpty()) {
            return;
        }

        String eventString = Test.isRunningTest() && triggerEventMock != null ? triggerEventMock : Trigger.operationType.name();

        List<MyTriggerSetting__mdt> triggerHandlerSettings = triggerEventsToTriggerHandlers.get(eventString);

        // YL's first attempt at an 'All' event ***************
        if (triggerHandlerSettings == null) {
            triggerHandlerSettings = new List<MyTriggerSetting__mdt>();
        }
        triggerHandlerSettings.addAll(triggerEventsToTriggerHandlers.get(ALL_EVENTS));
        // end YL's first attempt at an 'All' event ***************

        if (triggerHandlerSettings == null) {
            return;
        }

        for (MyTriggerSetting__mdt triggerHandlerSetting : triggerHandlerSettings) {
            Type handlerType = getTriggerHandlerType(triggerHandlerSetting.ClassNamespacePrefix__c, triggerHandlerSetting.Class__c);
            run(handlerType);
        }
    }

    //--------------------------------------------------------------
    // Methods to track updated records or if a record has changed fields
    //--------------------------------------------------------------

    static Set<Id> alreadyUpdatedIds = new Set<Id>();

    /**
     * add set of ids to updatedIds
     * @param  idSet usually Trigger.newMap.keyset()
     */
    global static void addUpdatedIds(Set<Id> idSet) {
        alreadyUpdatedIds.addAll(idSet);
    }


    /**
     * return all updated ids
     * @return   set of updated/already touched Ids
     */
    global static Set<Id> getUpdatedIds() {
        return alreadyUpdatedIds;
    }


    /**
    * returns a list of objects that have not been processed yet
    * @return           records[] not yet processed
    */
    global protected SObject[] getRecordsNotYetProcessed() {

        Set<Id> updatedIds = MyTriggers.getUpdatedIds();
        SObject[] recordsNotYetProcessed = Records.clone();
        recordsNotYetProcessed.clear();

        for (SObject record : Records) {
            if (!updatedIds.contains((Id) record.get('Id'))) {
                recordsNotYetProcessed.add(record);
            }
        }

        return recordsNotYetProcessed;
    }

    /**
     * returns true if a value of one of the specified fields has changed
     * @param  fieldList
     * @param  record
     * @param  recordOld
     */
    global static Boolean hasChangedFields(String[] fieldList, SObject record, SObject recordOld) {
        for (String field : fieldList) {
            if (record.get(field) != recordOld.get(field)) {
                return true;
            }
        }
        return false;
    }

    /**
     * returns true if a value of one of the specified fields has changed
     * @param  fieldList
     * @param  record
     * @param  recordOld
     */
    global static Boolean hasChangedFields(SObjectField[] fieldList, SObject record, SObject recordOld) {
        for (SObjectField field : fieldList) {
            if (record.get(field) != recordOld.get(field)) {
                return true;
            }
        }
        return false;
    }

    /**
     * returns a list of changed fields based on provided fieldList list
     * @param  fieldList
     * @param  record
     * @param  recordOld
     */
    global static String[] getChangedFields(String[] fieldList, SObject record, SObject recordOld) {
        String[] changedFieldNames = new String[]{
        };

        for (String field : fieldList) {
            if (record.get(field) != recordOld.get(field)) {
                changedFieldNames.add(field);
            }
        }

        return changedFieldNames;
    }


    /**
     * returns a list of changed fields based on provided fieldList list
     * @param  fieldList
     * @param  record
     * @param  recordOld
     */
    global static SObjectField[] getChangedFields(
            SObjectField[] fieldList,
            SObject record,
            SObject recordOld) {
        SObjectField[] changedFields = new SObjectField[]{
        };

        for (SObjectField field : fieldList) {
            if (record.get(field) != recordOld.get(field)) {
                changedFields.add(field);
            }
        }

        return changedFields;
    }

    //--------------------------------------------------------------
    // EVENT Control for advanced use cases
    //--------------------------------------------------------------

    static Map<Type, Set<String>> classNameToDisabledTriggerEventsMap = new Map<Type, Set<String>>();

    static Set<Type> alreadyCheckedClasses = new Set<Type>();


    /**
     * loads trigger event settings MyTriggerSetting__mdt
     * @param  triggerHandlerType
     * @param  forceInit            force reload of event settings
     */
    global static void setAllowedTriggerEvents(Type triggerHandlerType, Boolean forceInit) {
        if (alreadyCheckedClasses.contains(triggerHandlerType) && !forceInit) {
            return;
        }
        Set<String> events = getDisabledEvents(triggerHandlerType);
        Set<String> enabledEventsInSettings = new Set<String>();
        String classNameWithNamespace = triggerHandlerType.getName().toUpperCase();

        if (handlerClassesToTriggerHandlers != null && handlerClassesToTriggerHandlers.containsKey(classNameWithNamespace)) {
            for (MyTriggerSetting__mdt handlerSetting : handlerClassesToTriggerHandlers.get(classNameWithNamespace)) {

                // YL addition
                if(handlerSetting.Event__c == ALL_EVENTS){

                    for(System.TriggerOperation triggerOp : System.TriggerOperation.values()){
                        enabledEventsInSettings.add(triggerOp.name());
                    }
                }
                else{
                    enabledEventsInSettings.add(handlerSetting.Event__c);
                }
            }
        }

        for (System.TriggerOperation op : System.TriggerOperation.values()) {
            if (!enabledEventsInSettings.contains(op.name())) {
                events.add(op.name());
            }
        }

        alreadyCheckedClasses.add(triggerHandlerType);
    }

    /**
     * loads trigger event settings MyTriggerSetting__mdt
     * Method also works in subscriber org with hidden (public) trigger handlers from managed package
     * @param  namespacePrefix
     * @param  className
     * @param  forceInit
     */
    global static void setAllowedTriggerEvents(String namespacePrefix, String className, Boolean forceInit) {
        Type triggerHandlerType = getTriggerHandlerType(namespacePrefix, className);
        setAllowedTriggerEvents(triggerHandlerType, forceInit);
    }

    /**
     * returns set of disabled events
     * @param  className
     * @return           Set of disabled Event Names (e.g. 'AFTER_UPDATE')
     */
    global static Set<String> getDisabledEvents(Type className) {

        if (!classNameToDisabledTriggerEventsMap.containsKey(className)) {
            classNameToDisabledTriggerEventsMap.put(className, new Set<String>());
        }
        return classNameToDisabledTriggerEventsMap.get(className);
    }

    /**
     * returns set of disabled events
     * Method also works in subscriber org with hidden (public) trigger handlers from managed package
     * @param  namespacePrefix
     * @param  className
     * @return                 Set<String>
     */
    global static Set<String> getDisabledEvents(String namespacePrefix, String className) {
        Type triggerHandlerType = getTriggerHandlerType(namespacePrefix, className);
        return getDisabledEvents(triggerHandlerType);
    }

    /**
     * returns true if the specified event is disabled
     * @param  className className String
     * @param  event     event System.TriggerOperation
     * @return           Boolean
     */
    global static Boolean isDisabled(Type className, System.TriggerOperation event) {
        return getDisabledEvents(className).contains(event.name());
    }

    /**
     * returns true if the specified event is disabled
     * Method also works in subscriber org with hidden (public) trigger handlers from managed package
     * @param  namespacePrefix
     * @param  className
     * @param  event
     */
    global static Boolean isDisabled(String namespacePrefix, String className, System.TriggerOperation event) {
        Type triggerHandlerType = getTriggerHandlerType(namespacePrefix, className);
        return isDisabled(triggerHandlerType, event);
    }

    /**
     * getInsertEvents all insert events
     * @return   System.TriggerOperation[]
     */
    global static System.TriggerOperation[] getInsertEvents() {
        return new System.TriggerOperation[]{
                System.TriggerOperation.BEFORE_INSERT,
                System.TriggerOperation.AFTER_INSERT
        };
    }

    /**
     * get all upadte Events
     * @return   all update events
     */
    global static System.TriggerOperation[] getUpdateEvents() {
        return new System.TriggerOperation[]{
                System.TriggerOperation.BEFORE_UPDATE,
                System.TriggerOperation.AFTER_UPDATE
        };
    }

    /**
     * getDeleteEvents all delete events
     * @return   all delete events
     */
    global static System.TriggerOperation[] getDeleteEvents() {
        return new System.TriggerOperation[]{
                System.TriggerOperation.BEFORE_DELETE
                , System.TriggerOperation.AFTER_DELETE
        };
    }

    /**
     * list of all BEFORE System.TriggerOperation enums
     * @return   all before events
     */
    global static System.TriggerOperation[] getBeforeEvents() {
        return new System.TriggerOperation[]{
                System.TriggerOperation.BEFORE_INSERT
                , System.TriggerOperation.BEFORE_UPDATE
                , System.TriggerOperation.BEFORE_DELETE
        };
    }

    /**
     * list of all AFTER System.TriggerOperation enums
     * @return   all after events
     */
    global static System.TriggerOperation[] getAfterEvents() {
        return new System.TriggerOperation[]{
                System.TriggerOperation.AFTER_INSERT,
                System.TriggerOperation.AFTER_UPDATE,
                System.TriggerOperation.AFTER_DELETE,
                System.TriggerOperation.AFTER_UNDELETE
        };
    }


    /**
     * disables all events for System.Type MyClass
     * @param  myClass
     */
    global static void disable(Type MyClass) {

        System.TriggerOperation[] allEvents = new System.TriggerOperation[]{
        };
        allEvents.addAll(getBeforeEvents());
        allEvents.addAll(getAfterEvents());

        disable(MyClass, allEvents);
    }

    /**
     * disable disables all events for the trigger handler with given namespace and classname
     * Method also works in subscriber org with hidden (public) trigger handlers from managed package
     * @param  namespacePrefix
     * @param  className
     */
    global static void disable(String namespacePrefix, String className) {

        System.TriggerOperation[] allEvents = new System.TriggerOperation[]{
        };
        allEvents.addAll(getBeforeEvents());
        allEvents.addAll(getAfterEvents());

        disable(namespacePrefix, className, allEvents);
    }

    /**
     * removes all disabled events for the System.Type MyClass
     * @param  MyClass
     */
    global static void enable(Type MyClass) {
        getDisabledEvents(MyClass).clear();
    }

    /**
     * removes all disabled events for given ClassName and Namespace
     * Also works in subscriber org with packaged public trigger handlers implementing MyTriggers
     * @param  namespacePrefix String
     * @param  className       String
     */
    global static void enable(String namespacePrefix, String className) {
        Type triggerHandlerType = getTriggerHandlerType(namespacePrefix, className);
        enable(triggerHandlerType);
    }

    /**
     * disable disable all specified events for the System.Type MyClass
     * @param  MyClass
     * @param  events
     */
    global static void disable(Type MyClass, System.TriggerOperation[] events) {
        getDisabledEvents(MyClass).addAll(toStringEvents(events));
    }

    /**
     * disable all specified events for given ClassName and Namespace
     * Also works in subscriber org with packaged public trigger handlers implementing MyTriggers
     * @param  namespacePrefix
     * @param  className
     * @param  events
     */
    global static void disable(String namespacePrefix, String className, System.TriggerOperation[] events) {
        getDisabledEvents(namespacePrefix, className).addAll(toStringEvents(events));
    }

    /**
     * enable all specified events for the System.Type MyClass
     * @param  MyClass
     * @param  events
     */
    global static void enable(Type MyClass, System.TriggerOperation[] events) {
        getDisabledEvents(MyClass).removeAll(toStringEvents(events));
    }

    /**
     * enable all specified events for given ClassName and Namespace
     * Also works in subscriber org with packaged public trigger handlers implementing MyTriggers
     * @param  namespacePrefix
     * @param  className
     * @param  events
     */
    global static void enable(String namespacePrefix, String className, System.TriggerOperation[] events) {
        Type triggerHandlerType = getTriggerHandlerType(namespacePrefix, className);
        enable(triggerHandlerType, events);
    }

    /**
     * disable a single event for System.Type MyClass
     * @param  MyClass
     * @param  event
     */
    global static void disable(Type MyClass, System.TriggerOperation event) {
        getDisabledEvents(MyClass).add(event.name());
    }

    /**
     * disable a single event for ClassName and Namespace
     * Also works in subscriber org with packaged public trigger handlers implementing MyTriggers
     * @param  namespacePrefix
     * @param  className
     * @param  event
     */
    global static void disable(String namespacePrefix, String className, System.TriggerOperation event) {
        getDisabledEvents(namespacePrefix, className).add(event.name());
    }

    /**
     * enable a single event for System.Type MyClass
     * @param  MyClass
     * @param  event
     */
    global static void enable(Type MyClass, System.TriggerOperation event) {
        getDisabledEvents(MyClass).remove(event.name());
    }

    /**
     * enable a single event for ClassName and Namespace
     * Also works in subscriber org with packaged public trigger handlers implementing MyTriggers
     * @param  namespacePrefix
     * @param  className
     * @param  event
     */
    global static void enable(String namespacePrefix, String className, System.TriggerOperation event) {
        Type triggerHandlerType = getTriggerHandlerType(namespacePrefix, className);
        enable(triggerHandlerType, event);
    }

    /**
     * converts a Set of Event enums into Strings
     * @param  events
     * @return        Names of Enums
     */
    global static Set<String> toStringEvents(System.TriggerOperation[] events) {
        Set<String> output = new Set<String>();
        for (System.TriggerOperation e : events) {
            output.add(e.name());
        }
        return output;
    }

    //--------------------------------------------------------------
    // TRIGGER FRAMEWORK
    //--------------------------------------------------------------

    @TestVisible
    private static SObjectType executionContextSObjectType;

    private static Map<String, List<MyTriggerSetting__mdt>> triggerEventsToTriggerHandlers;

    private static Map<String, List<MyTriggerSetting__mdt>> handlerClassesToTriggerHandlers;

    /**
     * instantiates the applicable Trigger Handler object and passes it with Trigger context to run()
     * @param  handlerType
     */
    @TestVisible
    private static void run(Type handlerType) {
        run((MyTriggers) handlerType.newInstance(),
                handlerType,
                Trigger.isBefore,
                Trigger.isInsert,
                Trigger.isUpdate,
                Trigger.isDelete,
                Trigger.isUndelete,
                Trigger.new,
                Trigger.oldMap);
    }

    /**
     * routes Trigger contexts to methods
     * @param  handler
     * @param  handlerType
     * @param  isBefore
     * @param  isInsert
     * @param  isUpdate
     * @param  isDelete
     * @param  isUndelete
     * @param  triggerNew
     * @param  triggerOldMap
     */
    @TestVisible
    private static void run(MyTriggers handler, Type handlerType, Boolean isBefore, Boolean isInsert, Boolean isUpdate, Boolean isDelete, Boolean isUndelete, SObject[] triggerNew, Map<Id, SObject> triggerOldMap) {
        setAllowedTriggerEvents(handlerType, false);

        Set<String> disabledTriggerEvents = getDisabledEvents(handlerType);

        if (isBefore) {
            if (isInsert && !disabledTriggerEvents.contains(System.TriggerOperation.BEFORE_INSERT.name())) {
                handler.doConstruct(triggerNew).onBeforeInsert();
            } else if (isUpdate && !disabledTriggerEvents.contains(System.TriggerOperation.BEFORE_UPDATE.name())) {
                handler.doConstruct(triggerNew).onBeforeUpdate(triggerOldMap);
            } else if (isDelete && !disabledTriggerEvents.contains(System.TriggerOperation.BEFORE_DELETE.name())) {
                handler.doConstruct(triggerOldMap.values()).onBeforeDelete();
            }
        } else {
            if (isInsert && !disabledTriggerEvents.contains(System.TriggerOperation.AFTER_INSERT.name())) {
                handler.doConstruct(triggerNew).onAfterInsert();
            } else if (isUpdate && !disabledTriggerEvents.contains(System.TriggerOperation.AFTER_UPDATE.name())) {
                handler.doConstruct(triggerNew).onAfterUpdate(triggerOldMap);
            } else if (isDelete && !disabledTriggerEvents.contains(System.TriggerOperation.AFTER_DELETE.name())) {
                handler.doConstruct(triggerOldMap.values()).onAfterDelete();
            } else if (isUndelete && !disabledTriggerEvents.contains(System.TriggerOperation.AFTER_UNDELETE.name())) {
                handler.doConstruct(triggerNew).onAfterUndelete();
            }
        }
    }

    /**
     * Returns type of triggerHandler class according to given triggerHandlerSetting
     * @param  triggerHandlerSetting
     * @param  namespacePrefixes
     * @return handlerType
     */
    @TestVisible
    private static Type getTriggerHandlerType(String namespacePrefix, String className) {
        namespacePrefix = namespacePrefix == null ? '' : namespacePrefix;
        Type handlerType = Type.forName(namespacePrefix, className);

        //In case handler is part of the subscriber org
        if (handlerType == null) {
            handlerType = Type.forName('', className);
        }
        if (handlerType == null) {
            throw new MyTriggersException(Label.Errors_CannotFindTriggerHandlerClass + ':' + (namespacePrefix == null ? '' : namespacePrefix + '.') + className);
        }
        return handlerType;
    }

    /**
     * Set maps containing triggerHandlerSetting records for given SObjectType
     * @param  objectType SobjectType
     */
    @TestVisible
    private static void setTriggerHandlerMaps(SObjectType objectType) {
        triggerEventsToTriggerHandlers = new Map<String, List<MyTriggerSetting__mdt>>();
        handlerClassesToTriggerHandlers = new Map<String, List<MyTriggerSetting__mdt>>();
        for (MyTriggerSetting__mdt triggerSetting : getTriggerHandlerSettings(objectType)) {
            if (!triggerEventsToTriggerHandlers.containsKey(triggerSetting.Event__c)) {
                triggerEventsToTriggerHandlers.put(triggerSetting.Event__c, new List<MyTriggerSetting__mdt>());
            }
            triggerEventsToTriggerHandlers.get(triggerSetting.Event__c).add(triggerSetting);

            String classWithNamespaceKey = getClassNameWithNamespace(triggerSetting);
            if (!handlerClassesToTriggerHandlers.containsKey(classWithNamespaceKey)) {
                handlerClassesToTriggerHandlers.put(classWithNamespaceKey, new List<MyTriggerSetting__mdt>());
            }
            handlerClassesToTriggerHandlers.get(classWithNamespaceKey).add(triggerSetting);
        }
    }

    private static String getClassNameWithNamespace(MyTriggerSetting__mdt triggerHandlerSetting) {
        String namespacePrefix = String.isBlank(triggerHandlerSetting.ClassNamespacePrefix__c) ? '' : triggerHandlerSetting.ClassNamespacePrefix__c;
        return (String.isBlank(namespacePrefix) ? '' : namespacePrefix.toUpperCase() + '.') + triggerHandlerSetting.Class__c.toUpperCase();
    }

    /**
     * Returns list of triggerHandlerSetting for SObjectType
     * @param SObjectType
     * @return triggerHandlerSetting for SObjectType
     */
    private static List<MyTriggerSetting__mdt> getTriggerHandlerSettings(SObjectType objectType) {
        String SObjectName = objectType.getDescribe().getName();
        List<MyTriggerSetting__mdt> triggerHandlerSettings;

        if (Test.isRunningTest() && triggerHandlerSettingMocks != null) {
            triggerHandlerSettings = triggerHandlerSettingMocks;
        } else {
            triggerHandlerSettings = new List<MyTriggerSetting__mdt>(
            [
                    SELECT DeveloperName,
                            ClassNamespacePrefix__c,
                            Event__c,
                            SObject__c,
                            SObject__r.QualifiedApiName,
                            Class__c,
                            Order__c
                    FROM MyTriggerSetting__mdt
                    WHERE SObject__r.QualifiedApiName = :SObjectName
                    AND Active__c = TRUE
                    ORDER BY Order__c,
                            DeveloperName ASC
            ]);
        }

        return triggerHandlerSettings;
    }

}