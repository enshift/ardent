public class SObjectMetadata {
  public final static String EXCEPTION_SOBJECTNAME_NOT_FOUND = 'sobjectName not found';
  public final static String ESCEPTION_FIELDSETNAME_NOT_FOUND = 'fieldsetName not found';
  public static final String EXCEPTION_UKNOWN_RELATIONSHIP = 'Relationship {0} unknown on SObject {1}.';
  public static final String EXCEPTION_UKNOWN_RELATIONSHIP_FIELD = 'Relationship for {0} with parent lookup field {1} not known on parent {2}.';
  public static final String EXCEPTION_POLYMORPHIC_RELATIONSHIP = 'Relationship {0} is polymorphic, and is not yet supported by TestDataFactory.';

  public static List<String> getFieldNames(
    String sobjectName,
    String fieldsetName
  ) {
    Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();

    if (!globalDescribe.containsKey(sobjectName)) {
      throw new SObjectMetadataException(EXCEPTION_SOBJECTNAME_NOT_FOUND);
    }

    Schema.SObjectType sobjectType = globalDescribe.get(sobjectName);
    Schema.DescribeSObjectResult describe = sobjectType.getDescribe();
    Map<String, Schema.FieldSet> fieldsetMap = describe.fieldSets.getMap();

    if (!fieldsetMap.containsKey(fieldsetName)) {
      throw new SObjectMetadataException(ESCEPTION_FIELDSETNAME_NOT_FOUND);
    }

    Schema.FieldSet fieldset = fieldsetMap.get(fieldSetName);
    List<Schema.FieldSetMember> fields = fieldset.getFields();

    List<String> fieldNames = new List<String>();

    for (Schema.FieldSetMember field : fields) {
      fieldNames.add(field.getFieldPath());
    }

    return fieldNames;
  }

  public static Schema.SObjectType getSObjectType(String sobjectName) {
    Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();

    if (!globalDescribe.containsKey(sobjectName)) {
      throw new SObjectMetadataException(EXCEPTION_SOBJECTNAME_NOT_FOUND);
    }

    return globalDescribe.get(sobjectName);
  }

  public static Schema.ChildRelationship getChildRelationship(
    Schema.SObjectType sobjectType,
    String relationshipName
  ) {
    List<Schema.ChildRelationship> childRelationshipsForSObjectType = sobjectType.getDescribe()
      .getChildRelationships();
    Schema.ChildRelationship matchingChildRelationship;

    for (
      Schema.ChildRelationship childRelationship : childRelationshipsForSObjectType
    ) {
      if (
        relationshipName.equalsIgnoreCase(
          childRelationship.getRelationshipName()
        )
      ) {
        matchingChildRelationship = childRelationship;

        break;
      }
    }

    if (matchingChildRelationship == null) {
      throw new SObjectMetadataException(
        String.format(
          EXCEPTION_UKNOWN_RELATIONSHIP,
          new List<String>{
            relationshipName,
            sobjectType.getDescribe().getName()
          }
        )
      );
    }

    return matchingChildRelationship;
  }

  public static Schema.ChildRelationship getChildRelationship(
    Schema.SObjectType sobjectType,
    Schema.SObjectType childSObjectType,
    Schema.SObjectField parentLookup
  ) {
    Schema.ChildRelationship matchingChildRelationship;

    for (
      Schema.ChildRelationship childRelationship : sobjectType.getDescribe()
        .getChildRelationships()
    ) {
      if (
        childSObjectType == childRelationship.getChildSObject() &&
        parentLookup == childRelationship.getField()
      ) {
        matchingChildRelationship = childRelationship;

        break;
      }
    }

    if (matchingChildRelationship == null) {
      throw new SObjectMetadataException(
        String.format(
          EXCEPTION_UKNOWN_RELATIONSHIP_FIELD,
          new List<String>{
            childSObjectType.getDescribe().getName(),
            parentLookup.getDescribe().getName(),
            sobjectType.getDescribe().getName()
          }
        )
      );
    }

    return matchingChildRelationship;
  }

  public static Schema.SObjectField getParentLookupFieldByRelationshipName(
    SObjectType childSObjectType,
    String relationshipName
  ) {
    Schema.SObjectField parentLookupField;
    Map<String, Schema.SobjectField> fieldsByName = childSObjectType.getDescribe()
      .fields.getMap();

    for (Schema.SObjectField field : fieldsByName.values()) {
      if (
        relationshipName.equalsIgnoreCase(
          field.getDescribe().getRelationshipName()
        )
      ) {
        parentLookupField = field;
      }
    }

    if (parentLookupField == null) {
      throw new SObjectMetadataException(
        String.format(
          EXCEPTION_UKNOWN_RELATIONSHIP,
          new List<String>{
            relationshipName,
            childSObjectType.getDescribe().getName()
          }
        )
      );
    }

    return parentLookupField;
  }

  public static Schema.SObjectType getParentLookupSObjectType(
    Schema.SObjectField field
  ) {
    Schema.SObjectType parentSObjectType;

    if (field.getDescribe().isNamePointing()) {
      throw new SObjectMetadataException(
        String.format(
          EXCEPTION_POLYMORPHIC_RELATIONSHIP,
          new List<String>{ field.getDescribe().getRelationshipName() }
        )
      );
    } else if (field.getDescribe().getReferenceTo().size() == 1) {
      parentSObjectType = field.getDescribe().getReferenceTo().get(0);
    }

    if (parentSObjectType == null) {
      throw new SObjectMetadataException(
        'Could not get SObjectType from parent lookup field.'
      );
    }

    return parentSObjectType;
  }

  private class SObjectMetadataException extends Exception {
  }
}
