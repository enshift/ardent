@isTest
public class SObjectFactory {
  private static final String ID_PATTERN = '000000000000';
  private static Map<String, Integer> idCountByKeyPrefix = new Map<String, Integer>();
  private Schema.SObjectType sobjectType;
  private Map<String, Map<String, Object>> fieldValues;
  private Map<Schema.SObjectField, SObjectFactory> childFactories;
  private Integer numberOfSObjects;
  private Boolean shouldGenerateId;

  public static Id generateId(Schema.SObjectType sobjectType) {
    String keyPrefix = sobjectType.getDescribe().getKeyPrefix();
    Integer idCount = 0;

    if (idCountByKeyPrefix.containsKey(keyPrefix)) {
      idCount = idCountByKeyPrefix.get(keyPrefix);
    }

    idCountByKeyPrefix.put(keyPrefix, idCount += 1);

    String padding = ID_PATTERN.substring(0, 12 - idCount.format().length());

    return Id.valueOf(keyPrefix + padding + idCount);
  }

  private SObjectFactory(Schema.SObjectType sobjectType) {
    this.sobjectType = sobjectType;
    this.numberOfSObjects = 1;
    this.shouldGenerateId = true;
    this.fieldValues = new Map<String, Map<String, Object>>();
    this.childFactories = new Map<Schema.SObjectField, SObjectFactory>();
  }

  public static SObjectFactory newInstance(Schema.SObjectType sobjectType) {
    return new SObjectFactory(sobjectType);
  }

  public Schema.SObjectType getSObjectType() {
    return sobjectType;
  }

  public SObjectFactory setFields(
    Map<Schema.SObjectField, Object> fieldValues
  ) {
    for (Schema.SObjectField sobjectField : fieldValues.keySet()) {
      setField(sobjectField, fieldValues.get(sobjectField));
    }

    return this;
  }

  public SObjectFactory setField(
    Schema.SObjectField sobjectField,
    Object fieldValue
  ) {
    return setField(sobjectField.getDescribe().getLocalName(), fieldValue);
  }

  /**
   * Stores field values (ie: "FirstName" => "John") in a map, itself again mapped by relationship name (ie. 'Account.Contact' => Map).
   */
  public SObjectFactory setField(String path, Object fieldValue) {
    if (String.isBlank(path)) {
      throw new SObjectFactoryException(
        'You must provide a path for setField.'
      );
    }

    String normalizedPath = normalizeRelationshipName(path);
    Integer lastIndexOfDot = normalizedPath.lastIndexOf('.');
    String fieldName = normalizedPath.substring(
      lastIndexOfDot + 1,
      normalizedPath.length()
    );
    String relationshipPath = lastIndexOfDot == -1
      ? ''
      : normalizedPath.substring(0, lastIndexOfDot);

    Map<String, Object> relationshipFieldValues;

    if (
      fieldValues.containsKey(relationshipPath) &&
      fieldValues.get(relationshipPath) != null
    ) {
      relationshipFieldValues = fieldValues.get(relationshipPath);
    } else {
      relationshipFieldValues = new Map<String, Object>();
      fieldValues.put(relationshipPath, relationshipFieldValues);
    }

    relationshipFieldValues.put(fieldName, fieldValue);

    return this;
  }

  public SObjectFactory shouldGenerateId(Boolean shouldGenerateId) {
    this.shouldGenerateId = shouldGenerateId;

    return this;
  }

  public SObjectFactory setNumberOfSObjects(Integer numberOfSObjects) {
    this.numberOfSObjects = numberOfSObjects;

    return this;
  }

  /**
   * Define a parent relationship path to be recursively forged for the initial SObjects.
   * Eg: addParentRelationship('Contact.Account.Owner') will forge a parent Contact, parent Contact Account and parent Contact Account Owner.
   */
  public SObjectFactory addParentRelationship(String parentRelationshipPath) {
    String relationship = normalizeRelationshipName(parentRelationshipPath);

    if (!fieldValues.containsKey(relationship)) {
      fieldValues.put(relationship, null);
    }

    return this;
  }

  public SObject forgeSingle() {
    return forge().get(0);
  }

  public List<SObject> forge(Integer numberOfSObjects) {
    this.numberOfSObjects = numberOfSObjects;

    return forge();
  }

  public List<SObject> forge() {
    Set<String> relationships = fieldValues.keySet().clone();
    // Remove the base fields stored with an empty relationship name as the key, is technically not a relationship.;
    relationships.remove('');

    List<String> deduplicatedRelationships = getDeduplicatedRelationships(
      new List<String>(relationships)
    );
    List<SObject> sobjects = new List<SObject>();

    for (Integer i = 0; i < numberOfSObjects; i++) {
      Map<String, Object> sobjectFieldValues = fieldValues.get('');
      SObject sobjectInstance = forgeSObject(
        sobjectType,
        sobjectFieldValues,
        shouldGenerateId
      );

      for (String relationship : deduplicatedRelationships) {
        sobjectInstance = forgeSObjectTree(
          sobjectInstance,
          sobjectType,
          relationship,
          fieldValues
        );
      }

      for (Schema.SObjectField childLookupField : childFactories.keySet()) {
        SObjectFactory childFactory = childFactories.get(childLookupField);
        List<SObject> childSObjects = childFactory.forge();

        sobjectInstance = addChildren(
          sobjectInstance,
          childFactory.getSObjectType(),
          childLookupField,
          childSObjects
        );
      }

      sobjects.add(sobjectInstance);
    }

    return sobjects;
  }

  // TODO: rename to putChildren, rename setField to put()? Reflects the map functionality of setting and overwriting something.
  public SObjectFactory setChildren(
    Schema.SObjectField childLookupField,
    SObjectFactory childFactory
  ) {
    childFactories.put(childLookupField, childFactory);

    return this;
  }

  /**
   * To avoid running forgeObject() multiple times on the same relationship trees (ie. Account & Account.Owner), we deduplicate the relationships here.
   */
  @TestVisible
  private static List<String> getDeduplicatedRelationships(
    List<String> relationships
  ) {
    List<String> deduplicatedRelationships = relationships.clone();
    Set<Integer> indexesToRemove = new Set<Integer>();

    for (Integer i = 0; i < relationships.size(); i++) {
      String possibleLongestRelationship = relationships.get(i);

      for (Integer u = 0; u < relationships.size(); u++) {
        String relationship = relationships.get(u);
        Boolean possibleLongestIsContainedByRelationship = relationship.startsWith(
          possibleLongestRelationship
        );
        Boolean relationshipIsContainedByPossibleLongest = possibleLongestRelationship.startsWith(
          relationship
        );

        if (i == u) {
          continue;
        } else if (possibleLongestIsContainedByRelationship) {
          indexesToRemove.add(i);
        } else if (relationshipIsContainedByPossibleLongest) {
          indexesToRemove.add(u);
        }
      }
    }

    List<Integer> indexesToRemoveList = new List<Integer>(indexesToRemove);

    for (Integer i = 0; i < indexesToRemoveList.size(); i++) {
      Integer indexToRemove = indexesToRemoveList.get(i);
      deduplicatedRelationships.remove(indexToRemove - i);
    }

    return deduplicatedRelationships;
  }

  private static SObject forgeSObject(
    Schema.SObjectType sobjectType,
    Map<String, Object> fieldValues,
    Boolean shouldGenerateId
  ) {
    Id sobjectId;

    if (shouldGenerateId) {
      sobjectId = generateId(sobjectType);
    }

    SObject sobjectInstance = sobjectType.newSObject(sobjectId);
    sobjectInstance = putProperties(
      sobjectInstance,
      sobjectType,
      normalizeFieldValueKeys(fieldValues, sobjectType)
    );

    return sobjectInstance;
  }

  /**
   * Used because deserializing untyped objects to SObjects have case sensitive field and relationship names.
   */
  private static Map<String, Object> normalizeFieldValueKeys(
    Map<String, Object> fieldValues,
    Schema.SObjectType sobjectType
  ) {
    Map<String, Object> sobjectFieldValues = new Map<String, Object>();

    if (fieldValues != null && !fieldValues.isEmpty()) {
      for (String fieldName : fieldValues.keySet()) {
        Schema.SObjectField sobjectField = sobjectType.getDescribe()
          .fields.getMap()
          .get(fieldName);

        if (sobjectField == null) {
          throw new SObjectFactoryException(
            String.format(
              'Field {0} is not known on {1}',
              new List<String>{
                fieldName,
                sobjectType.getDescribe().getLocalName()
              }
            )
          );
        }

        sobjectFieldValues.put(
          sobjectField.getDescribe().getLocalName(),
          fieldValues.get(fieldName)
        );
      }
    }

    return sobjectFieldValues;
  }

  /**
   * Forges parent SObjects for a relationship path (eg: Contact.Account.Owner)
   *
   * First, traverse the parental hierarchy upwards to figure out SObjectTypes and SObjectFields
   * Then, traverse the relationship downwards starting from the top parent.
   * We do this because we have to reassign the objects to be able to mutate immutable relationships with putProperty(), and reassigning removes the
   * link with the child that's still referencing the immutable parent.
   *
   * At every relationship level, we check if the SObject was already provisioned in a previous iteration, and reuse that if applicable to allow for
   * shared parent relationship paths (eg Account.Owner and Account.Parent not overwriting each other's Accounts).
   */
  private static SObject forgeSObjectTree(
    SObject sobjectInstance,
    Schema.SObjectType sobjectType,
    String parentRelationshipPath,
    Map<String, Map<String, Object>> fieldValues
  ) {
    List<String> relationshipNames = parentRelationshipPath.split('\\.');
    Schema.SObjectType childSObjectTypeToIterate = sobjectType;

    List<Schema.SObjectField> parentLookupFields = new List<Schema.SObjectField>();
    List<Schema.SObjectType> parentSObjectTypes = new List<Schema.SObjectType>();

    for (String relationshipName : relationshipNames) {
      Schema.SObjectField parentLookupField = SObjectMetadata.getParentLookupFieldByRelationshipName(
        childSObjectTypeToIterate,
        relationshipName
      );
      Schema.SObjectType parentSObjectType = SObjectMetadata.getParentLookupSObjectType(
        parentLookupField
      );

      parentLookupFields.add(parentLookupField);
      parentSObjectTypes.add(parentSObjectType);

      childSObjectTypeToIterate = parentSObjectType;
    }

    SObject parentSObject;
    SObject childSObject;

    for (Integer i = 1; i <= relationshipNames.size(); i++) {
      Integer currentIndex = relationshipNames.size() - i;
      String relationshipName = relationshipNames.get(currentIndex);
      Schema.SObjectType childSObjectType;

      Schema.SObjectField parentLookupField = parentLookupFields.get(
        currentIndex
      );
      Schema.SObjectType parentSObjectType = parentSObjectTypes.get(
        currentIndex
      );

      List<String> sharedRelationshipNames = new List<String>();

      for (Integer s = 0; s < currentIndex; s++) {
        sharedRelationshipNames.add(relationshipNames.get(s));
      }

      String sharedRelationshipPath = String.join(sharedRelationshipNames, '.');
      String currentRelationshipPath;

      if (String.isBlank(sharedRelationshipPath)) {
        currentRelationshipPath = relationshipName;
      } else {
        currentRelationshipPath = String.join(
          new List<String>{ sharedRelationshipPath, relationshipName },
          '.'
        );
      }

      SObject sharedSObject;

      if (!String.isBlank(sharedRelationshipPath)) {
        sharedSObject = getParent(sobjectInstance, sharedRelationshipPath);
      }

      if (parentSObject == null) {
        Map<String, Object> parentFieldValues = fieldValues.get(
          currentRelationshipPath
        );
        parentSObject = forgeSObject(
          parentSObjectType,
          parentFieldValues,
          true
        );
      }

      // Reached original sobjectInstance
      if (currentIndex == 0) {
        childSObjectType = sobjectType;
        childSObject = sobjectInstance;
      } else if (sharedSObject != null) {
        childSObject = sharedSObject;
        childSObjectType = sharedSObject.getSObjectType();
      } else {
        Map<String, Object> childFieldValues = fieldValues.get(
          sharedRelationshipPath
        );

        childSObjectType = parentSObjectTypes.get(currentIndex - 1);
        childSObject = forgeSObject(childSObjectType, childFieldValues, true);
      }

      childSObject = putProperties(
        childSObject,
        childSObjectType,
        new Map<String, Object>{
          parentLookupField.getDescribe()
            .getRelationshipName() => parentSObject,
          parentLookupField.getDescribe().getName() => parentSObject.Id
        }
      );

      parentSObject = childSObject;
    }

    return childSObject;
  }

  @TestVisible
  private static SObject getParent(
    SObject sobjectInstance,
    String relationshipPath
  ) {
    List<String> relationshipNames = relationshipPath.split('\\.');
    SObject parentSObject = sobjectInstance;

    for (String relationshipName : relationshipNames) {
      if (parentSObject != null) {
        parentSObject = parentSObject.getSObject(relationshipName);
      }
    }

    return parentSObject;
  }

  private static String normalizeRelationshipName(String relationshipName) {
    return relationshipName.normalizeSpace().toLowerCase();
  }

  /**
   * Sets a child relationship collection on a parent SObject, and its inverse lookup on the children, just as you would see when performing an inner
   * query. The name of the relationship is automatically determined by the combination of the children's sobjectType and the parent lookup field.
   *
   * Note that the method cannot mutate a given SObject, so you must redeclare the original SObject, or appoint a new one. The same goes for the
   * children, only the redeclared SObject's children will contain a lookup to their parent.
   *
   * Example: For an Account and a collection of Contacts for example, it would result in a property 'Contacts' on the Account, with the collection of
   * Contacts, and the AccountId for each Contact being completed with the parent Account's Id.
   */
  public static SObject addChildren(
    SObject sobjectInstance,
    Schema.SObjectType childSObjectType,
    Schema.SObjectField parentLookup,
    List<SObject> children
  ) {
    Schema.SObjectType sobjectType = sobjectInstance.getSObjectType();
    List<SObject> childrenWithParents = new List<SObject>();

    for (SObject childSobject : children) {
      SObject childWithParents = putProperties(
        childSobject,
        childSObjectType,
        new Map<String, Object>{
          parentLookup.getDescribe().getRelationshipName() => sobjectInstance,
          parentLookup.getDescribe().getLocalName() => sobjectInstance.Id
        }
      );

      childrenWithParents.add(childWithParents);
    }

    Map<String, Object> untypedRelationship = new Map<String, Object>();
    untypedRelationship.put('totalSize', children.size());
    untypedRelationship.put('done', true);
    untypedRelationship.put('records', childrenWithParents);

    Map<String, Object> untypedSObject = getUntypedObject(sobjectInstance);
    Schema.ChildRelationship childRelationship = SObjectMetadata.getChildRelationship(
      sobjectType,
      childSObjectType,
      parentLookup
    );
    untypedSObject.put(
      childRelationship.getRelationshipName(),
      untypedRelationship
    );

    sobjectInstance = getSObject(untypedSObject, sobjectType);

    return sobjectInstance;
  }

  public static SObject putProperty(
    SObject sobjectInstance,
    Schema.SObjectType sobjectType,
    String propertyName,
    Object property
  ) {
    return putProperties(
      sobjectInstance,
      sobjectType,
      new Map<String, Object>{ propertyName => property }
    );
  }

  public static SObject putProperties(
    SObject sobjectInstance,
    Schema.SObjectType sobjectType,
    Map<String, Object> properties
  ) {
    Map<String, Object> untypedObject = getUntypedObject(sobjectInstance);
    untypedObject.putAll(properties);
    SObject updatedSObjectInstance = getSObject(untypedObject, sobjectType);

    return updatedSObjectInstance;
  }

  private static Map<String, Object> getUntypedObject(Object objectInstance) {
    String serializedObject = JSON.serialize(objectInstance);
    Map<String, Object> untypedObject = (Map<String, Object>) JSON.deserializeUntyped(
      serializedObject
    );

    return untypedObject;
  }

  private static SObject getSObject(
    Map<String, Object> untypedObject,
    Schema.SObjectType sobjectType
  ) {
    String serializedUntypedObject = JSON.serialize(untypedObject);
    SObject sobjectInstance = (SObject) JSON.deserialize(
      serializedUntypedObject,
      System.Type.forName(sobjectType.getDescribe().getName())
    );

    return sobjectInstance;
  }

  public class SObjectFactoryException extends Exception {
  }
}
