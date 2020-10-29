public with sharing abstract class Model {
  /**
   * Stores all model SObjectTypes by their model names.
   */
  private static Map<String, Schema.SObjectType> sobjectTypeByModelName;

  static {
    sobjectTypeByModelName = new Map<String, Schema.SObjectType>();
  }

  public static void setTypes(
    System.Type modelType,
    Schema.SObjectType sobjectType
  ) {
    sobjectTypeByModelName.put(modelType.getName(), sobjectType);
  }

  public static Model newInstance(System.Type type) {
    Model modelInstance = (Model) Type.newInstance();
    Schema.SObjectType sobjectType = sobjectTypeByModelName.get(type.getName());
    SObject sobjectInstance = sobjectType.newSObject();

    modelInstance.record = sobjectInstance;

    return modelInstance;
  }

  private String key;
  private SObject record;
}
