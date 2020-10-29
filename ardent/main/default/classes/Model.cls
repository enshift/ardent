public with sharing abstract class Model {
  /**
   * Stores all model SObjectTypes by their model names.
   */
  private static Map<String, Schema.SObjectType> sobjectTypeByModelName;
  private static Integer globalUniqueKey = 0;

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
    return createNewInstance(type, null);
  }

  public static Model newInstance(System.Type type, SObject sobjectInstance) {
    return createNewInstance(type, sobjectInstance);
  }

  private static Model createNewInstance(
    System.Type type,
    SObject sobjectInstance
  ) {
    Model modelInstance = (Model) Type.newInstance();
    Schema.SObjectType sobjectType = sobjectTypeByModelName.get(type.getName());

    if (sobjectInstance == null) {
      sobjectInstance = sobjectType.newSObject();
    }

    modelInstance.record = sobjectInstance;

    modelInstance.key = !String.isBlank(sobjectInstance.Id)
      ? String.valueOf(sobjectInstance.Id)
      : getUniqueKey();

    return modelInstance;
  }

  public static String getUniqueKey() {
    return String.valueOf(globalUniqueKey++);
  }

  public String key { get; private set; }
  public SObject record { get; private set; }
}
