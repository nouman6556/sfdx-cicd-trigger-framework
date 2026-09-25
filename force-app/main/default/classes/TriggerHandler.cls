/**
 * Lightweight trigger framework.
 *  - One trigger per object, all logic in a handler subclass
 *  - Context-specific virtual methods (beforeInsert, afterUpdate, ...)
 *  - Per-handler bypass (e.g. during data loads) and recursion guard
 *
 * Usage:
 *   trigger AccountTrigger on Account (before insert, before update, after insert, after update) {
 *       new AccountTriggerHandler().run();
 *   }
 */
public virtual inherited sharing class TriggerHandler {

    private static final Set<String> BYPASSED = new Set<String>();
    private static final Map<String, Integer> RUN_COUNT = new Map<String, Integer>();

    @TestVisible private System.TriggerOperation operation;
    @TestVisible private List<SObject> newList;
    @TestVisible private Map<Id, SObject> oldMap;
    private Integer maxLoops = 5;

    public TriggerHandler() {
        if (Trigger.isExecuting) {
            this.operation = Trigger.operationType;
            this.newList = Trigger.new;
            this.oldMap = Trigger.oldMap;
        }
    }

    public void run() {
        String name = handlerName();
        if (BYPASSED.contains(name) || operation == null) {
            return;
        }
        Integer count = RUN_COUNT.containsKey(name) ? RUN_COUNT.get(name) + 1 : 1;
        if (count > maxLoops) {
            throw new TriggerHandlerException('Maximum recursion (' + maxLoops + ') reached for ' + name);
        }
        RUN_COUNT.put(name, count);
        try {
            switch on operation {
                when BEFORE_INSERT  { beforeInsert(newList); }
                when BEFORE_UPDATE  { beforeUpdate(newList, oldMap); }
                when BEFORE_DELETE  { beforeDelete(oldMap); }
                when AFTER_INSERT   { afterInsert(newList); }
                when AFTER_UPDATE   { afterUpdate(newList, oldMap); }
                when AFTER_DELETE   { afterDelete(oldMap); }
                when AFTER_UNDELETE { afterUndelete(newList); }
            }
        } finally {
            RUN_COUNT.put(name, count - 1);
        }
    }

    public TriggerHandler setMaxLoops(Integer max) { this.maxLoops = max; return this; }

    public static void bypass(String handlerName) { BYPASSED.add(handlerName); }
    public static void clearBypass(String handlerName) { BYPASSED.remove(handlerName); }
    public static Boolean isBypassed(String handlerName) { return BYPASSED.contains(handlerName); }

    protected virtual void beforeInsert(List<SObject> newRecords) {}
    protected virtual void beforeUpdate(List<SObject> newRecords, Map<Id, SObject> oldRecords) {}
    protected virtual void beforeDelete(Map<Id, SObject> oldRecords) {}
    protected virtual void afterInsert(List<SObject> newRecords) {}
    protected virtual void afterUpdate(List<SObject> newRecords, Map<Id, SObject> oldRecords) {}
    protected virtual void afterDelete(Map<Id, SObject> oldRecords) {}
    protected virtual void afterUndelete(List<SObject> newRecords) {}

    private String handlerName() {
        return String.valueOf(this).substring(0, String.valueOf(this).indexOf(':'));
    }

    public class TriggerHandlerException extends Exception {}
}
