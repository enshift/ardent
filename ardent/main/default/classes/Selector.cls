public with sharing class Selector {
  Schema.SObjectType sobjectType;
  Set<String> includeFields;

  public Selector(Schema.SObjectType sobjectType) {
    this.includeFields = new Set<String>();
    this.sobjectType = sobjectType;
  }

  public String getQuery() {
    return 'SELECT ' +
      getSelectFieldsString() +
      ' FROM ' +
      sobjectType.getDescribe().getLocalName();
  }

  public List<SObject> execute(){
    return Database.query(getQuery());
  }

  private String getSelectFieldsString() {
    Set<String> selectFieldsForQuery = includeFields;

    if (includeFields.isEmpty()) {
      selectFieldsForQuery = getSObjectTypeFields(this.sobjectType);
    }

    return String.join(new List<String>(selectFieldsForQuery), ',');
  }

  private Set<String> getSObjectTypeFields(Schema.SObjectType sobjectType) {
    Map<String, Schema.SObjectField> fieldByName = sobjectType.getDescribe()
      .fields.getMap();

    return fieldByName.keySet();
  }
}
