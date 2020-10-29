public with sharing abstract class Model {
  /**
   * Stores all model SObjectTypes by their model names.
   */
  private static Map<String, Schema.SObjectType> sobjectTypeByModelName;
  private static Integer globalUniqueKey;

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

    modelInstance.key = !String.isBlank(sobjectInstance.Id)
      ? sobjectInstance.Id
      : getUniqueKey();

    return modelInstance;
  }

  public static String getUniqueKey() {
    if (globalUniqueKey == null) {
      globalUniqueKey = 0;
    }

    return String.valueOf(globalUniqueKey++);
  }

  public String key { get; private set; }
  public SObject record { get; private set; }
}
